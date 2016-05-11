;♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥;      
;♥ .      _ _  __   .                                               ♥;
;♥     * ( | )/_/       ; ConnectedNES                              ♥;
;♥  . __( >O< )    *    ; an internet-connected NES                 ♥;
;♥    \_\(_|_)  +       ; Electronic Love Operation 2016            ♥;
;♥  +       .         .                                             ♥;
;♥                                                                  ♥;
;♥                      ; ConnectedNES displays internet content    ♥;
;♥                      ; that is processed on a node.js backend,   ♥;
;♥                      ; pushed wirelessly to a Particle Photon    ♥;
;♥                      ; through exposed cloud functions, then     ♥;
;♥                      ; streamed byte-by-byte to the NES through  ♥;
;♥                      ; its second controller port.               ♥;
;♥                                                                  ♥;
;♥                      ; This source code is fully commented.      ♥;
;♥                      ; Hopefully it is of help to those wishing  ♥;
;♥                      ; to know more about how NES code is        ♥;
;♥                      ; written. To compile from source, use      ♥;
;♥                      ; NESASM3 (not included). NESASM3 usage is  ♥;
;♥                      ; <filepath> nesasm3 connected.asm          ♥;
;♥                                                                  ♥;
;♥                      ; Many thanks are in order to my friend     ♥;
;♥                      ; Andy Reitano, who wrote Transfer Tool, an ♥;
;♥                      ; Arduino-to-NES protocol that has been     ♥;
;♥                      ; adapted for use here.                     ♥;
;♥                                                                  ♥;
;♥                      ; Rachel Simone Weil                        ♥;
;♥                      ; http://nobadmemories.com                  ♥;
;♥                      ; http://github.com/hxlnt                   ♥;
;♥                                                                  ♥;
;♥                                                                  ♥;
;♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥;

                    
                                                        
;;;;;;;; + 1.0 NESASM3.0 HEADER + ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
                                                                    ;;
    .inesprg 2          ; 2 16-KB banks PRG data (32KB total)       ;;
    .ineschr 1          ; 1 8-KB bank CHR data (8KB total)          ;;
    .inesmap 0          ; No mapper                                 ;;
    .inesmir 0          ; Vertical mirroring                        ;;
                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;; + 2.0 VARIABLES + ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
    .rsset $0000        ; Start variables at $0000 (zero page)      ;; 
;music			.rs 16	; Reserve 16 bytes for music				;;        
buttons1        .rs 1   ; Buttons pressed (P1)                      ;;      
buttons1pending .rs 1   ; Buttons pressed but not read (P1)         ;;          
buttons1read    .rs 1   ; Buttons pressed that need to be read (P1) ;; 
buttons2        .rs 1   ; Buttons pressed (P2)                      ;;      
buttons2pending .rs 1   ; Buttons pressed but not read (P2)         ;;          
buttons2read    .rs 1   ; Buttons pressed that need to be read (P2) ;;     
framecounter    .rs 1   ; General-purpose frame counter             ;;
printablebyte	.rs 1   ; Byte delivered from the line from Photon  ;; 
tweetscroll	    .rs 1   ; Horizontal scroll for incoming tweet      ;;
printoutlobyte  .rs 1   ; Low byte of print address                 ;;
printouthibyte	.rs 1	; High byte of print address                ;;
randompointer   .rs 1   ; Points to a table of "random" numbers     ;;
                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;; + 3.0 CONSTANTS + ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
; INITADDR = $A999        ; Init address for music                    ;;
LOADADDR = $A6E0        ; Load address for music                    ;;
; PLAYADDR = $A99C        ; Play address for music                    ;;
                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;; + 4.0 GAME CODE: BANK 0 + ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
    .bank 0             ; Bank 0                                    ;;
    .org $8000          ; begins at address $8000                   ;;
                                                                    ;;
;;;;;;;;;; 4.1 Console initialization ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
Reset:                  ; This code runs when console is reset      ;;
    SEI                                                             ;;
    CLD                                                             ;;
    LDX #$40                                                        ;;
    STX $4017                                                       ;;
    LDX #$FF                                                        ;;
    TXS                                                             ;;
    INX                                                             ;;
    STX $2000                                                       ;;
    STX $2001                                                       ;;
    STX $4010                                                       ;;
Vblank1:                ; Wait for first V-blank                    ;;
    BIT $2002                                                       ;;
    BPL Vblank1                                                     ;;
ClearMem:               ; Clear memory                              ;;                    
    LDA #$00                                                        ;;
    STA $0000, x                                                    ;;
    STA $0100, x                                                    ;;
    STA $0300, x                                                    ;;
    STA $0400, x                                                    ;;
    STA $0500, x                                                    ;;
    STA $0600, x                                                    ;;
    STA $0700, x                                                    ;;
    LDA #$FE                                                        ;;
    STA $0200, x                                                    ;;
    INX                                                             ;;
    BNE ClearMem                                                    ;;
Vblank2:                ; Wait for second V-blank                   ;;
    BIT $2002                                                       ;;
    BPL Vblank2                                                     ;; 
                                                                    ;;
;;;;;;;;; 4.2 Game initialization ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;  
    ; LDA #$00            ; Initialize sound registers                ;;
    ; LDX #$00                                                        ;;
; ClearSoundLoop:                                                     ;;
    ; STA $4000,x                                                     ;;
    ; INX                                                             ;;
    ; CPX #$0F                                                        ;;  
    ; BNE ClearSoundLoop                                              ;;
    ; LDA #$10                                                        ;;
    ; STA $4010                                                       ;;
    ; LDA #$00                                                        ;;
    ; STA $4011                                                       ;;
    ; STA $4012                                                       ;;
    ; STA $4013                                                       ;;
    ; LDA #%00001111                                                  ;;
    ; STA $4015                                                       ;;  
    ; LDA #$00                                                        ;;
    ; LDX #$00                                                        ;;
    ; JSR INITADDR                                                    ;;
    LDA #$00            ; Reset framecounter                        ;;
    STA framecounter                                                ;;
	STA printablebyte   ; Clear printable byte tile                 ;;
	LDA #$21            ; Set printing location to origin ($2104)   ;;
	STA printouthibyte                        
	LDA #$04
	STA printoutlobyte
    JSR TurnScreenOff   ; Disable screen rendering                  ;;
    JSR LoadBG          ; Load background                           ;;
    JSR LoadSpr         ; Load sprites                              ;;
    JSR TurnScreenOn    ; Enable screen rendering                   ;;
                                                                    ;;
;;;;;;;;;;;; 4.3 Game loop ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
GameLoop:  
    LDX #$00
ResetSpritePosLoop:
    LDA $0300,x
    CMP #$e2
    BEQ ResetTopSprite
    TXA
    CLC
    ADC #$40
    BEQ ResetSpritePosLoopDone
    TAX
    JMP ResetSpritePosLoop
ResetTopSprite:
    LDA randompointer
    AND #%00111111
    TAY
    LDA random,y
    STA $0303,x
    STA $030F,x
    STA $031B,x
    STA $0327,x
    CLC
    ADC #$08
    STA $0307,x
    STA $0313,x
    STA $031F,x
    STA $032B,x
    STA $0333,x
    STA $0337,x
    STA $033B,x
    STA $033F,x
    CLC
    ADC #$08
    STA $030B,x
    STA $0317,x
    STA $0323,x
    STA $032F,x
    INY
    STY randompointer
ResetSpritePosLoopDone:   
StringAnim:                                                      ;;
    LDA framecounter
    AND #%00001111
    CMP #%00001111
    BNE StringAnimDone
    LDX #$00
StringAnimLoop:
    LDA $0332,x
    EOR #%01000000
    STA $0332,x
    STA $0336,x
    STA $033a,x
    STA $033e,x
    TXA
    CLC
    ADC #$40
    BEQ StringAnimDone
    TAX
    JMP StringAnimLoop
StringAnimDone:
    JMP GameLoop        ; Infinite main game loop                   ;;
                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;; + 5.0 GAME CODE: BANK 1 + ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
    .bank 1             ; Bank 1                                    ;;
    .org LOADADDR       ; Starts at music LOADADDR                  ;;
    ; .incbin "music.nsf" ; Include binary NSF music file             ;;
                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;; + 6.0 GAME CODE: BANK 2 + ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
    .bank 2             ; Bank 2                                    ;;
    .org $C000          ; Starts at memory address $C000            ;;
                                                                    ;;
;;;;;;;;;;;; 6.1 NMI ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
NMI:                    ; Non-maskable interrupt                    ;;
    PHA                 ; Back up registers                         ;;
    TXA                                                             ;;
    PHA                                                             ;;
    TYA                                                             ;;
    PHA                                                             ;;
    LDX framecounter    ; Add one to the frame counter              ;;
    INX                                                             ;;
    STX framecounter                                                ;;
DisplayBytes:           ; Display letters from Photon               ;;
    JSR ReadController1
	JSR ReadController2
	LDA buttons2		
    STA printablebyte
	BEQ NoBytes
    CMP #$17
    BEQ ResetMsg
PrintTest:
    LDA printouthibyte
    CMP #$21
    BEQ Print
    LDA printoutlobyte
    CMP #$D3
    BCC Print
    LDA #$DB
    STA printablebyte
    JMP UpdateMsgcounter
    JMP Print
;    JMP NMIDone
ResetMsg:
    LDA #$02
    STA printablebyte
	LDA #$21
    STA printouthibyte
    LDA #$04
	STA printoutlobyte
Print:
	LDA printouthibyte
	STA $2006
	LDA printoutlobyte
	STA $2006
	LDA printablebyte
	STA $2007
UpdateMsgcounter:
	LDA printoutlobyte
	CMP #$1b
	BEQ EoLine1and5
	CMP #$5b
	BEQ EoLine2and6
	CMP #$9b
	BEQ EoLine3and7
	CMP #$db
	BEQ EoLine4or8
	INC printoutlobyte
NoBytes:
	JMP NMIDone
EoLine1and5:
	LDA #$44
	STA printoutlobyte
    JMP NMIDone
EoLine2and6:
	LDA #$84
	STA printoutlobyte
	JMP NMIDone
EoLine3and7:
    LDA #$c4
    STA printoutlobyte
    JMP NMIDone
EoLine4or8:
    LDA printouthibyte
    CMP #$22
    BEQ EoLine8
	LDA #$22
    STA printouthibyte
    LDA #$04
	STA printoutlobyte
	JMP NMIDone
EoLine8:
	LDA #$21
    STA printouthibyte
    LDA #$04
	STA printoutlobyte
NMIDone:                ; Final actions in NMI                      ;;
    JSR SpriteDMA       ; Bring in sprite data 					    ;;
SpriteAnim:    
    LDX #$00
SpriteAnimLoop:
    LDA $0300,x
    SEC
    SBC #$01
    STA $0300,x
    LDA $0380,x
    SEC
    SBC #$02
    STA $0380,x
    TXA
    CLC
    ADC #$04
    CMP #$80
    BEQ ResetSpritePos
    TAX
    JMP SpriteAnimLoop
ResetSpritePos:
	LDA #$00
	STA $2005
	STA $2005
	JSR TurnScreenOn
    ;JSR PLAYADDR        ; Update audio                              ;;
    PLA                 ; Restore registers                         ;;
    TAY                                                             ;;
    PLA                                                             ;;
    TAX                                                             ;;
    PLA                                                             ;;
    RTI                 ; NMI is done                               ;;
                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
;;;;;;;;;;;; 6.2 Subroutines ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
SpriteDMA:              ; Sprite DMA subroutine                     ;;
    LDA #$00                                                        ;;
    STA $2003                                                       ;;
    LDA #$03                                                        ;;
    STA $4014                                                       ;;
    RTS                                                             ;;
LoadDefaultPal:         ; "Load Default palette" subroutine         ;;
    LDA $2002                                                       ;;
    LDA #$3F                                                        ;;
    STA $2006                                                       ;;
    LDA #$00                                                        ;;
    STA $2006                                                       ;;
    LDX #$00                                                        ;;
LoadDefaultPalLoop:                                                 ;;
    LDA defaultpal, x                                               ;;
    STA $2007                                                       ;;
    INX                                                             ;;
    CPX #$20                                                        ;;
    BNE LoadDefaultPalLoop                                          ;;
    RTS                                                             ;;
; LoadDarkPal:            ; "Load Dark palette" subroutine            ;;
    ; LDA $2002                                                       ;;
    ; LDA #$3F                                                        ;;
    ; STA $2006                                                       ;;
    ; LDA #$00                                                        ;;
    ; STA $2006                                                       ;;
    ; LDX #$00                                                        ;;
; LoadDarkPalLoop:                                                    ;;
    ; LDA darkpal, x                                                  ;;
    ; STA $2007                                                       ;;
    ; INX                                                             ;;
    ; CPX #$20                                                        ;;
    ; BNE LoadDarkPalLoop                                             ;;
    ; RTS                                                             ;;
; LoadBrightPal:          ; "Load Bright palette" subroutine          ;;
    ; LDA $2002                                                       ;;
    ; LDA #$3F                                                        ;;
    ; STA $2006                                                       ;;
    ; LDA #$00                                                        ;;
    ; STA $2006                                                       ;;
    ; LDX #$00                                                        ;;
; LoadBrightPalLoop:                                                  ;;
    ; LDA brightpal, x                                                ;;
    ; STA $2007                                                       ;;
    ; INX                                                             ;;
    ; CPX #$20                                                        ;;
    ; BNE LoadBrightPalLoop                                           ;;
    ; RTS                                                             ;;
; LoadPastelPal:          ; "Load Pastel palette" subroutine          ;;
    ; LDA $2002                                                       ;;
    ; LDA #$3F                                                        ;;
    ; STA $2006                                                       ;;
    ; LDA #$00                                                        ;;
    ; STA $2006                                                       ;;
    ; LDX #$00                                                        ;;
; LoadPastelPalLoop:                                                  ;;
    ; LDA pastelpal, x                                                ;;
    ; STA $2007                                                       ;;
    ; INX                                                             ;;
    ; CPX #$20                                                        ;;
    ; BNE LoadPastelPalLoop                                           ;;
    ; RTS                                                             ;;
LoadBG:                 ; "Load background" subroutine              ;;
    LDA $2002                                                       ;;
    LDA #$3F                                                        ;;
    STA $2006                                                       ;;
    LDA #$00                                                        ;;
    STA $2006                                                       ;;
    LDX #$00                                                        ;;
LoadPalLoop:            ; Default palette is loaded on reset        ;;
    LDA defaultpal, x                                               ;;
    STA $2007                                                       ;;
    INX                                                             ;;
    CPX #$20                                                        ;;
    BNE LoadPalLoop                                                 ;;
    LDA $2002                                                       ;;
    LDA #$20                                                        ;;
    STA $2006                                                       ;;
    LDA #$00                                                        ;;
    STA $2006                                                       ;;
    LDX #$00                                                        ;;
LoadTitleNewNam1:       ; Load first set of 256 background tiles    ;;
    LDA background1,x                                               ;;
    STA $2007                                                       ;;
    INX                                                             ;;
    BNE LoadTitleNewNam1                                            ;;
LoadTitleNewNam2:       ; Load second set of 256 background tiles   ;;
    LDA background2,x                                               ;;
    STA $2007                                                       ;;
    INX                                                             ;;
    BNE LoadTitleNewNam2                                            ;;
LoadTitleNewNam3:       ; Load third set of 256 background tiles    ;;
    LDA background3,x                                               ;;
    STA $2007                                                       ;;
    INX                                                             ;;
    BNE LoadTitleNewNam3                                            ;;
LoadTitleNewNam4:       ; Load fourth set of background tiles       ;;
    LDA background4,x                                                        ;;
    STA $2007                                                       ;;
    INX                                                             ;;
    CPX #$E0            ; (Don't have to load all 256)              ;;
    BNE LoadTitleNewNam4                                            ;;
LoadAttr:               ; Load initial attribute values for BG      ;;
    LDA #$23                                                        ;;
    STA $2006                                                       ;;
    LDA #$c0                                                        ;;
    STA $2006                                                       ;;
    LDX #$00                                                        ;;
LoadAttrLoop:                                                       ;;
    LDA attr, x                                                     ;;
    STA $2007                                                       ;;
    INX                                                             ;;
    CPX #$40                                                        ;;
    BNE LoadAttrLoop                                                ;;
    RTS                                                             ;;
LoadSpr:                ; Load initial sprite values                ;;
    LDX #$00                                                        ;;
LoadSprLoop:                                                        ;;
    LDA tweetatme,x                                                 ;;
    STA $0300,x                                                     ;;
    INX                                                             ;;                
    BNE LoadSprLoop                                                 ;;
    RTS                                                             ;;
TurnScreenOn:           ; Enable screen rendering                   ;;
    LDA #%10010000                                                  ;;
    STA $2000                                                       ;;
    LDA #%00011010                                                  ;;
    STA $2001                                                       ;;
    RTS                                                             ;;
TurnScreenOff:          ; Disable screen rendering                  ;;
    LDA #$00                                                        ;;
    STA $2000                                                       ;;
    STA $2001                                                       ;;
    RTS                                                             ;;
ReadController1:        ; Read the P1 controller                    ;;
    LDA #$01                                                        ;;          
    STA $4016                                                       ;;
    LDA #$00                                                        ;;
    STA $4016                                                       ;;
    LDX #$08                                                        ;;
ReadController1Loop:                                                ;;
    LDA $4016                                                       ;;
    LSR A                                                           ;;
    ROL buttons1                                                    ;;
    DEX                                                             ;;
    BNE ReadController1Loop                                         ;;
    LDA buttons1pending ; Note: This code is helpful in helping to  ;;
    EOR #%11111111      ; distinguish between reading a continuous  ;;                                          
    AND buttons1        ; button press and a single button press    ;;
    STA buttons1read    ; Often, we want to read the first button   ;;
    LDA buttons1        ; value sent and then ignore subsequent     ;;
    STA buttons1pending ; reads until the button is released        ;;
    RTS                                                             ;;
ReadController2:        ; Read the P1 controller                    ;;
    LDA #$01                                                        ;;          
    STA $4017                                                       ;;
    LDA #$00                                                        ;;
    STA $4017                                                       ;;
    LDX #$08                                                        ;;
ReadController2Loop:                                                ;;
    LDA $4017                                                       ;;
    LSR A                                                           ;;
    ROL buttons2                                                    ;;
    DEX                                                             ;;
    BNE ReadController2Loop                                         ;;
    LDA buttons2pending ; Note: This code is helpful in helping to  ;;
    EOR #%11111111      ; distinguish between reading a continuous  ;;                                          
    AND buttons2        ; button press and a single button press    ;;
    STA buttons2read    ; Often, we want to read the first button   ;;
    LDA buttons2        ; value sent and then ignore subsequent     ;;
    STA buttons2pending ; reads until the button is released        ;;
    RTS                                                             ;;
                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
;;;;;;;;;;;; 6.3 Binary data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
background1:            ; First 256-tile set of background          ;;
    .incbin "loadingscreen1.nam"                                            ;;
background2:            ; Second 256-tile set of background         ;;
    .incbin "loadingscreen2.nam"                                            ;;
background3:            ; Third 256-tile set of background          ;;
    .incbin "loadingscreen3.nam"                                            ;;
background4:            ; Third 256-tile set of background          ;;
    .incbin "loadingscreen4.nam"                                            ;;
defaultpal:             ; Default color palette                     ;;
	.incbin "test.pal" ;;
attr:                   ; Color attribute table                     ;;
	.incbin "test.atr"
tweetatme:
	.db $30,$04,$20,$c0 ; First row of balloon 1                    ;;
	.db $30,$05,$20,$c8
    .db $30,$06,$20,$d0
    .db $38,$14,$20,$c0 ; Second row of balloon 1
    .db $38,$15,$20,$c8
    .db $38,$16,$20,$d0                                             ;;
    .db $40,$24,$20,$c0 ; Third row of balloon 1                    ;;
    .db $40,$25,$20,$c8
    .db $40,$26,$20,$d0
    .db $48,$34,$20,$c0 ; Fourth row of balloon 1                   ;;
    .db $48,$35,$20,$c8
    .db $48,$36,$20,$d0
    .db $50,$45,$20,$c8 ; Beginning of string 1
    .db $58,$55,$20,$c8    
    .db $60,$65,$20,$c8    
    .db $68,$75,$20,$c8   
	.db $70,$04,$21,$80 ; First row of balloon 2                    ;;
	.db $70,$05,$21,$88
    .db $70,$06,$21,$90
    .db $78,$14,$21,$80 ; Second row of balloon 2
    .db $78,$15,$21,$88
    .db $78,$16,$21,$90                                             ;;
    .db $80,$24,$21,$80 ; Third row of balloon 2                    ;;
    .db $80,$25,$21,$88
    .db $80,$26,$21,$90
    .db $88,$34,$21,$80 ; Fourth row of balloon 2                   ;;
    .db $88,$35,$21,$88
    .db $88,$36,$21,$90
    .db $90,$45,$21,$88 ; Beginning of string 2
    .db $98,$55,$21,$88    
    .db $a0,$65,$21,$88    
    .db $a8,$75,$21,$88        
	.db $b0,$04,$22,$40 ; First row of balloon 3                    ;;
	.db $b0,$05,$22,$48
    .db $b0,$06,$22,$50
    .db $b8,$14,$22,$40 ; Second row of balloon 3
    .db $b8,$15,$22,$48
    .db $b8,$16,$22,$50                                             ;;
    .db $c0,$24,$22,$40 ; Third row of balloon 3                    ;;
    .db $c0,$25,$22,$48
    .db $c0,$26,$22,$50
    .db $c8,$34,$22,$40 ; Fourth row of balloon 3                   ;;
    .db $c8,$35,$22,$48
    .db $c8,$36,$22,$50
    .db $d0,$45,$22,$48 ; Beginning of string 3
    .db $d8,$55,$22,$48    
    .db $e0,$65,$22,$48    
    .db $e8,$75,$22,$48
	.db $f0,$04,$23,$00 ; First row of balloon 4                    ;;
	.db $f0,$05,$23,$08
    .db $f0,$06,$23,$10
    .db $f8,$14,$23,$00 ; Second row of balloon 2
    .db $f8,$15,$23,$08
    .db $f8,$16,$23,$10                                             ;;
    .db $00,$24,$23,$00 ; Third row of balloon 2                    ;;
    .db $00,$25,$23,$08
    .db $00,$26,$23,$10
    .db $08,$34,$23,$00 ; Fourth row of balloon 2                   ;;
    .db $08,$35,$23,$08
    .db $08,$36,$23,$10
    .db $10,$45,$23,$08 ; Beginning of string 2
    .db $18,$55,$23,$08    
    .db $20,$65,$23,$08    
    .db $28,$75,$23,$08                                             ;;
    
random:
    .db $de,$0f,$9f,$12,$e7,$2e,$34,$21,$cd,$ac,$52,$76,$4b,$63,$88,$bc
    .db $4b,$ba,$09,$9a,$55,$a9,$1a,$cc,$28,$39,$6e,$46,$77,$e7,$81,$d0
    .db $87,$76,$23,$08,$65,$99,$45,$a5,$54,$ba,$17,$3b,$66,$d4,$c3,$e9
    .db $32,$c3,$ab,$0c,$dd,$21,$12,$4c,$80,$6d,$51,$ef,$7f,$8f,$b0,$91
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    

;;;;;;;; + 7.0 GAME CODE: BANK 2 + ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
    .bank 3             ; Bank 3                                    ;;
    .org $E000          ; Begins at memory address $E000            ;;
    .org $FFFA          ; Final three bytes (vectors):              ;;
    .dw NMI             ; When an NMI happens, jump to NMI          ;;
    .dw Reset           ; On reset/power on, jump to Reset          ;;
    .dw 0               ; IRQ disabled                              ;;
                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
  
;;;;;;;; + 8.0 GRAPHICS DATA: BANK 4 + ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                    ;;
    .bank 4             ; Bank 4                                    ;;
    .org $0000          ; Starts at $0000 (CHR)                     ;;
    .incbin "ascii.chr"   ; Include graphics binary                 ;;
                                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
