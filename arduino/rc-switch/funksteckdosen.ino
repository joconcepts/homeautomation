#include <SPI.h>
#include <Ethernet.h>
#include <EthernetUdp.h>
#include <RCSwitch.h>

RCSwitch mySwitch = RCSwitch();

byte mac[] = {
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED
};
IPAddress ip(192, 168, 2, 190);

unsigned int localPort = 8888;      // local port to listen on

// buffers for receiving and sending data
char packetBuffer[UDP_TX_PACKET_MAX_SIZE]; //buffer to hold incoming packet,

// An EthernetUDP instance to let us send and receive packets over UDP
EthernetUDP Udp;

void setup() {
  // start the Ethernet and UDP:
  Ethernet.begin(mac, ip);
  Udp.begin(localPort);

  Serial.begin(9600);

  mySwitch.enableTransmit(9);
}

char *cmd, *group, *id;
void loop() {
  // if there's data available, read a packet
  int packetSize = Udp.parsePacket();
  if (packetSize)
  {
    Serial.print("Received packet of size ");
    Serial.print(packetSize);
    Serial.print(" with content: ");
    
    // read the packet into packetBufffer
    Udp.read(packetBuffer, UDP_TX_PACKET_MAX_SIZE);

    packetBuffer[strlen(packetBuffer)-1] = '\0';
    
    Serial.println(packetBuffer);

    cmd = strtok(packetBuffer, " ");
    group = strtok(NULL, " ");
    id = strtok(NULL, " ");

    Serial.print("cmd: ");
    Serial.print(cmd);
    Serial.print(", group: ");
    Serial.print(group);
    Serial.print(", id: ");
    Serial.println(id);

    if(String(cmd).equals("on")) {
      mySwitch.switchOn(group, id);
    } else if(String(cmd).equals("off")) {
      mySwitch.switchOff(group, id);
    }

    cmd = NULL;
    group = NULL;
    id = NULL;
  }
  delay(10);
}

