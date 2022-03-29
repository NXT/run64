.scope rstack
  .align 2 
  IP: .word 0
  STACK: .res 128
  SP: .byte 0
  .proc push
    ;PrintChr '<'
    ldx SP
    lda IP
    sta STACK,x
    lda IP+1
    sta STACK+1,x
    inc SP
    inc SP
    rts 
  .endproc
  .proc pop
    ;PrintChr '>'
    dec SP
    dec SP
    ldx SP
    lda STACK,x
    sta IP
    lda STACK+1,x
    sta IP+1
    rts 
  .endproc
.endscope

.macro RPush 
  jsr rstack::push
.endmacro

.macro RPop arg1
  jsr rstack::pop
.endmacro

.macro Peek address, offset
  IMov TMP, address
  .ifnblank offset
    IAddB TMP, offset
  .endif
  ldx #0
  lda (TMP,x)
.endmacro

.macro Read address
  Peek address
  tax
  IInc address
  txa 
.endmacro

.macro WriteA address
  PokeA {address}
  IInc {address}
.endmacro

.macro PokeA address, offset
  pha
  IMov TMP, address
  .ifnblank offset
    IAddB TMP, offset
  .endif
  ldx #0
  pla
  sta (TMP,x)
.endmacro

.macro Poke addr1, addr2
  .scope
    pha
    IMov rewrite+1, address
    pla
    rewrite:
    sta $FEDA
  .endscope
.endmacro



.scope runtime
  ptr = cursor
  IP = rstack::IP

  .proc doPtr
    jsr load_ip
    clc
    rts
  .endproc

  .proc doIf
    SpDec
    IsTrue 0
    IfFalse
      jmp doPtr     ; if false move IP to else
    EndIf
    IAddB IP, 3   ; otherwise continue
    clc
    rts
  .endproc
  
  .proc doUnless
    SpDec
    IsTrue 0
    IfTrue
      jmp doPtr     ; if false move IP to else
    EndIf
    IAddB IP, 3   ; otherwise continue
    clc
    rts
  .endproc

  .proc doNop
    IInc IP
    clc
    rts 
  .endproc

  .proc exec
    IMov ptr, IP
    ldy #0
    lda (ptr),y
    JmpEq #bytecode::NAT, doProc
    and #15
    JmpEq #bytecode::GTO, doPtr
    JmpEq #bytecode::NOP, doNop
    JmpEq #bytecode::RET, doRet
    JmpEq #bytecode::INT, doInt
    JmpEq #bytecode::STR, doStr
    JmpEq #bytecode::RUN, doRun
    JmpEq #bytecode::IF0, doIf
    JmpEq #bytecode::IF0, doUnless
  .endproc

.proc doStr
  IAddB IP, 3
  
  PushFrom IP
  jmp doPtr
.endproc

.proc doInt
    SpInc
    Peek IP,1
    SetLo 1
    Peek IP,2
    SetHi 1
    IAddB IP,3

    clc
    rts
  .endproc

  .proc doProc  ; only jump and return
    Peek IP,1
    sta rewrite+1
    Peek IP,2
    sta rewrite+2
    rewrite:
    jsr $FEDA
    jmp doRet
  .endproc

  .proc doRun
    IAddB IP,3
    RPush
    jsr load_ip
    clc
    rts
  .endproc 

  .proc doRet
    IfFalse rstack::SP
      inc ended 
    Else 
      RPop
    EndIf
    rts
  .endproc

  .proc load_ip
    iny
    lda (ptr),y
    sta IP
    iny 
    lda (ptr),y
    sta IP+1
    rts
  .endproc 
  ended: .byte 0


  .proc start
    CClear ended
    CClear rstack::SP
    rts
  .endproc

  .proc run
    jsr start
  .endproc 
  .proc run_to_end
    Begin
      BraTrue ended, break
      jsr exec
    Again
    rts
  .endproc

  
.endscope
