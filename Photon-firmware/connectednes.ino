// ConnectedNES Particle Photon firmware
// 

#define NES_CLOCK D1                                // Red wire
#define NES_LATCH D2                                // Orange wire
#define NES_DATA D3                                 // Yellow wire
#define LED 7

volatile unsigned char latchedByte;                 // Controller press byte value = one letter in tweet
volatile unsigned char bitCount;                    // A single LDA $4017 (get one bit from "controller press")
volatile unsigned char byteCount;                   // How many bytes have already been printed
volatile unsigned char bytesToTransfer;             // How many bytes are left to print

unsigned char tweetData[192];                       // Array that will hold 192 hex values representing tweet data      


//////////////////////////////////////////


void setup() {
    
    Particle.subscribe("tweet", myHandler);
    
    pinMode(NES_CLOCK, INPUT);                      // Set NES controller red wire (clock) as an input
    pinMode(NES_LATCH, INPUT);                      // Set NES controller orange wire (latch) as an input
    pinMode(NES_DATA, OUTPUT);                      // Set NES controller yellow wire (data) as an output
    
    attachInterrupt(NES_CLOCK, ClockNES, FALLING);  // When NES clock ends, execute ClockNES
    attachInterrupt(NES_LATCH, LatchNES, RISING);   // When NES latch fires, execure LatchNES
    
    pinMode(LED, OUTPUT);                             // Turn off the Photon's on-board LED
    digitalWrite(LED, LOW);                           //
    
    byteCount = 0;                                  // Initialize byteCount at zero, no letters printed to screen
    bytesToTransfer = 0;                            // Initialize bytesToTransfer at zero, no letters waiting to print to screen

    }


//////////////////////////////////////////


void loop() {                                       // 'Round and 'round we go       

    }                                        


//////////////////////////////////////////


void myHandler(String event, String data) {
    digitalWrite(LED, HIGH);                        // Turn on the Photon's on-board LED
    char inputStr[193];
    data.toCharArray(inputStr, 193);
    tweetData[0] = 0xE8;
    static int i=1;
    for(i=1; i<192; i++) { tweetData[i] = inputStr[i]; }
    memset(&inputStr[0], 0, sizeof(inputStr));
    bytesToTransfer = 192;
    byteCount = 0;
    digitalWrite(LED, LOW);                         // Turn off the Photon's on-board LED
    }


////////////////////////////////////////


void ClockNES() {
    digitalWrite(NES_DATA, latchedByte & 0x01);
    latchedByte >>= 1;
    bitCount++;
    }

    
/////////////////////////////////////////


void LatchNES() {
    if (byteCount == bytesToTransfer) {
        latchedByte = 0xFF;
        digitalWrite(NES_DATA, latchedByte & 0x01);
        latchedByte >>= 1;
        bitCount = 0;
        }
    else {
        latchedByte = tweetData[byteCount] ^ 0xFF;
        digitalWrite(NES_DATA, latchedByte & 0x01);
        latchedByte >>= 1;
        bitCount = 0;
        byteCount++;
        }
    }
