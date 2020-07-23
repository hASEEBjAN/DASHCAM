#include "esp_camera.h"
#include "EEPROM.h"
#include <WiFi.h>
#include <WebServer.h>
#include <WebSocketsServer.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define EEPROM_SIZE 128

#define CAMERA_MODEL_AI_THINKER
#define WiFi_TryConnect_TimeOut 20000.0 // ilang  milliseconds maghihintay ang esp32 sa pag connect

#define Port_WebServer 8000
#define Port_WebSocket 8888
#ifndef LED_BUILTIN
#define LED_BUILTIN 13 //HERE it should be 0
#endif

#include "camera_pins.h"

IPAddress staticip;
float customtimer = 0;
WebServer server(Port_WebServer);
WebSocketsServer webSocket = WebSocketsServer(Port_WebSocket);

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

const int ledPin = 22;
const int modeAddr = 0;
const int wifiAddr = 10;

int modeIdx;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      BLEDevice::startAdvertising();
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();

      if (value.length() > 0) {
        Serial.print("Value : ");
        Serial.println(value.c_str());
        writeString(wifiAddr, value.c_str());
        modeIdx = 0;
        return;
      }
    }

    void writeString(int add, String data) {
      int _size = data.length();
      for (int i = 0; i < _size; i++) {
        EEPROM.write(add + i, data[i]);
      }
      EEPROM.write(add + _size, '\0');
      EEPROM.commit();
    }
};

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);

  if (!EEPROM.begin(EEPROM_SIZE)) {
    delay(1000);
  }

  modeIdx = EEPROM.read(modeAddr);
  Serial.print("modeIdx : ");
  Serial.println(modeIdx);

  EEPROM.write(modeAddr, modeIdx != 0 ? 0 : 1);
  EEPROM.commit();
  
  if (modeIdx != 0) {
    //BLE MODE
    digitalWrite(ledPin, true);
    Serial.println("BLE MODE");
    bleTask();
    modeIdx = 0;
  } else {
    //WIFI MODE
    digitalWrite(ledPin, false);
    Serial.println("WIFI MODE");
    wifiTask();
  }
}

void bleTask() {
  // Create the BLE Device
  BLEDevice::init("ESP32 THAT PROJECT");

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );

  pCharacteristic->setCallbacks(new MyCallbacks());
  // https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.descriptor.gatt.client_characteristic_configuration.xml
  // Create a BLE Descriptor
  pCharacteristic->addDescriptor(new BLE2902());

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
  BLEDevice::startAdvertising();
  Serial.println("Waiting a client connection to notify...");
}

void wifiTask() {
  String receivedData;
  receivedData = read_String(wifiAddr);

  if (receivedData.length() > 0) {
    String wifiName = getValue(receivedData, ',', 0);
    String wifiPassword = getValue(receivedData, ',', 1);

    if (wifiName.length() > 0 && wifiPassword.length() > 0) {


      Serial.print("WifiName : ");
      Serial.println(wifiName);

      Serial.print("wifiPassword : ");
      Serial.println(wifiPassword);

      camera_config_t config;
      config.ledc_channel = LEDC_CHANNEL_0;
      config.ledc_timer = LEDC_TIMER_0;
      config.pin_d0 = Y2_GPIO_NUM;
      config.pin_d1 = Y3_GPIO_NUM;
      config.pin_d2 = Y4_GPIO_NUM;
      config.pin_d3 = Y5_GPIO_NUM;
      config.pin_d4 = Y6_GPIO_NUM;
      config.pin_d5 = Y7_GPIO_NUM;
      config.pin_d6 = Y8_GPIO_NUM;
      config.pin_d7 = Y9_GPIO_NUM;
      config.pin_xclk = XCLK_GPIO_NUM;
      config.pin_pclk = PCLK_GPIO_NUM;
      config.pin_vsync = VSYNC_GPIO_NUM;
      config.pin_href = HREF_GPIO_NUM;
      config.pin_sscb_sda = SIOD_GPIO_NUM;
      config.pin_sscb_scl = SIOC_GPIO_NUM;
      config.pin_pwdn = PWDN_GPIO_NUM;
      config.pin_reset = RESET_GPIO_NUM;
      config.xclk_freq_hz = 10000000; // accourding sa research ko ito 10MHz ang nagbibigay ng best FPS
      config.pixel_format = PIXFORMAT_JPEG;

      if (psramFound()) {
        Serial.println("PSRAM was FOUND!!!");
        config.frame_size = FRAMESIZE_QVGA;
        config.jpeg_quality = 15;

        config.fb_count = 2;
      } else {
        config.frame_size = FRAMESIZE_QQVGA;
        config.jpeg_quality = 12;
        config.fb_count = 1;
      }

      // camera init
      esp_err_t err = esp_camera_init(&config);
      if (err != ESP_OK) {
        Serial.printf("Camera init failed with error 0x%x", err);
        return;
      }

      sensor_t * s = esp_camera_sensor_get();
      if (s->id.PID == OV3660_PID) {
        s->set_vflip(s, 0);//flip it back
        s->set_brightness(s, 1);//up the blightness just a bit
        s->set_saturation(s, 1);//lower the saturation
      }
      //drop down frame size for higher initial frame rate
      //s->set_framesize(s, FRAMESIZE_QVGA);
      s->set_framesize(s, FRAMESIZE_QQVGA);

      WiFi.begin(wifiName.c_str(), wifiPassword.c_str());

      Serial.print("Connecting to Wifi");
      while (WiFi.status() != WL_CONNECTED) {
        Serial.print(".");
        delay(300);
      }

      Serial.print(String("\nWiFi connected using:\nSSID:") + wifiName + String("\nPassword:") + wifiPassword + String("\n"));
      staticip = WiFi.localIP(); // get the current ip of this device assigned by the router
      staticip[3] = 184; // set the fourth octet to 184
      if (!WiFi.config(staticip, WiFi.gatewayIP(), WiFi.subnetMask())) { // set the static ip address
        Serial.println("STA Failed to configure");
      }

      // get the current ip of this device aFpsssigned by the router

      server.on("/", []()
      {
        server.send(200, "text/html", ""
                    "<html>\n"
                    "    <head>\n"
                    "        <title>Thesis Camera Test</title>\n"
                    "        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
                    "<style> *{ margin:0; } img { display: absolute; margin: 0 !important; height: 100vh;  width: 100vw; } </style>"
                    "    </head>\n"
                    "    <body style=\"background-color:#FFFFFF\">\n"
                    "        <img src=\"\">\n"
                    "        <script>\n"
                    "            const img = document.querySelector('img');\n"
                    "            const WS_URL = 'ws:///" + staticip.toString() + ":" + String(Port_WebSocket) + "';\n"
                    "            const ws = new WebSocket(WS_URL);\n"
                    "            let urlObject;\n"
                    "            ws.onopen = () => console.log(`Connected to ${WS_URL}`);\n"
                    "            ws.onmessage = message => {\n"
                    "                const arrayBuffer = message.data;\n"
                    "                if(urlObject){\n"
                    "                    URL.revokeObjectURL(urlObject);\n"
                    "                }\n"
                    "                urlObject = URL.createObjectURL(new Blob([arrayBuffer]));\n"
                    "                img.src = urlObject;\n"
                    "            }\n"
                    "        </script>\n"
                    "    </body>\n"
                    "</html>");
      });
      server.begin();
      webSocket.begin();

      Serial.println("Camera Ready! type this URL to access the Video Stream:");
      Serial.print(staticip);
      Serial.println(String(":") + Port_WebServer);

      pinMode(LED_BUILTIN, OUTPUT);


    }
  }
}


String read_String(int add) {
  char data[100];
  int len = 0;
  unsigned char k;
  k = EEPROM.read(add);
  while (k != '\0' && len < 500) {
    k = EEPROM.read(add + len);
    data[len] = k;
    len++;
  }
  data[len] = '\0';
  return String(data);
}

String getValue(String data, char separator, int index) {
  int found = 0;
  int strIndex[] = {0, -1};
  int maxIndex = data.length() - 1;

  for (int i = 0; i <= maxIndex && found <= index; i++) {
    if (data.charAt(i) == separator || i == maxIndex) {
      found++;
      strIndex[0] = strIndex[1] + 1;
      strIndex[1] = (i == maxIndex) ? i + 1 : i;
    }
  }
  return found > index ? data.substring(strIndex[0], strIndex[1]) : "";
}

void loop() {
  // put your main code here, to run repeatedly:
  webSocket.loop();
  server.handleClient();

  if (webSocket.connectedClients(false) <= 0) return;
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    esp_camera_fb_return(fb);
    return;
  }
  if (fb->format != PIXFORMAT_JPEG) {
    Serial.println("Non-JPEG data not implemented");
    return;
  }
  webSocket.broadcastBIN((const uint8_t*) fb->buf, fb->len);
  //webSocket.sendBIN(0,(const uint8_t*) fb->buf,fb->len);
  Serial.println(String("RAW Binary Array Count = ") + String(fb->len));
  Serial.println(String("Heap Size = ") + String(ESP.getFreeHeap()));
  esp_camera_fb_return(fb);

  if ((webSocket.connectedClients(false) > 0 || digitalRead(LED_BUILTIN) == HIGH) && millis() - customtimer > 1000 / webSocket.connectedClients(false))
  {
    //Serial.println(String("Connected Clients:") + String(webSocket.connectedClients(false)));
    if (digitalRead(LED_BUILTIN) != HIGH)
    {
      digitalWrite(LED_BUILTIN, HIGH);
      Serial.println("HIGH");
    }
    else
    {
      digitalWrite(LED_BUILTIN, LOW);
      Serial.println("LOW");
    }
    customtimer = millis();
  }

  //webSocket.disconnect(); // disconnectclient
}
