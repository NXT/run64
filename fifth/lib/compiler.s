  PrintString "HOW THE"
  writer: .word  HEAP_END

  .scope compiler
  pointer = $FD
  IP = writer
  offset:
    .word 0
  eof:
    .byte 0
  error:
    .byte 0
  cstack:
    .res 128
  csp:
    .byte 0  

  .proc advance_pointer
    inc pointer
    BraTrue skip
    inc pointer+1
    skip:
    rts
  .endproc

  .proc advance_offset
    ;IMov offset, input::ptr
    IMov offset, pointer
    rts
  .endproc

  .proc reset_pointer
    ;IMov offset, input::ptr
    IMov pointer,offset
    rts
  .endproc


  .proc skip_space 
    jsr reset_pointer
    ldx #0
    loop:
    ;jsr input::read
    lda (pointer,x)
    BraFalse stop
    BraEq #13, stop
    BraGe #33, done
    jsr advance_pointer
    jmp loop
    done:
    jsr advance_offset
    rts 
    stop:
    jsr advance_offset
    inc eof
    rts 
  .endproc

  .proc print_next_word
    jsr reset_pointer
    ldx #0
    Begin
    ;jsr input:read
    lda (pointer,x)
    BraLt #33, break
    jsr CHROUT
    jsr advance_pointer
    Again
    rts 
  .endproc


  .proc parse_word
    jsr reset_pointer
    ;jsr input::read
    ldx #0
    lda (pointer,x)
    JmpEq #34, parse_string
    JmpEq #'$', parse_hex
    BraLt #'0', not_dec
    BraGe #'9'+1, not_dec
    decimal:
    jmp parse_dec
    not_dec:
    entry:
    jmp parse_entry
  .endproc
  result: .word 0

  .proc parse_hex
    IClear result
    jsr reset_pointer
    jsr advance_pointer
    ldx #0
    hex_digit:
    ; jsr input::read
    lda (pointer,x)
    and #$7f

    cmp #33
    bcc hex_done
    sub #$30
    bmi hex_error
    cmp #10
    bcc hex_found

    sec
    sbc #7
    cmp #9
    bcc hex_error
    cmp #16
    bcs hex_error

    hex_found:
    IShiftLeft result
    IShiftLeft result
    IShiftLeft result
    IShiftLeft result
    
    BCS hex_error
    
    ORA result
    STA result
    BCS hex_error
    jsr advance_pointer
    jmp hex_digit 

    hex_error:
    jmp die
    hex_done:
    jsr advance_offset
    jmp write_int
  .endproc ; parse_hex

  .proc parse_dec
    IClear result
    jsr reset_pointer
    ldx #0
    dec_digit:
    
      ; jsr input::read
      lda (pointer,x)
      and #$7f
      
      BraLt #33, dec_done

      sub #'0'

      BraNeg dec_error
      BraGe #10, dec_error
      
      pha
        IMov temp, result
      pla

      IShiftLeft result
      IShiftLeft result
      
      pha
        IAdd result, temp
      pla

      IShiftLeft result

      BCS dec_error
      
      IAddA result 
      jsr advance_pointer
      jmp dec_digit

    dec_error:
      jmp die
      rts 

    dec_done:
      jsr advance_offset
      jmp write_int
    temp: .word 0
  .endproc ; parse_dec

  


  .proc parse_string
    lda #bytecode::tSTR
    jsr write

    Stash IP
    IAddB IP,2
    jsr advance_pointer ; consume start quote
    ldx #0
    Begin
    ; jsr input::read
    lda (pointer,x)
    BraLt #32, catch
    BraEq #34, break
    jsr write
    jsr advance_pointer
    Again
    jsr advance_pointer ; consume end quote
    jsr advance_offset  
    lda #0
    jsr write       ; write terminating zero

    Unstash cursor    ; write 
    ldy #0
    lda IP
    sta (cursor),y
    iny
    lda IP+1
    sta (cursor),y
    rts
    catch:
    jmp die
  .endproc  

  .proc parse_entry
    jsr vocab::reset_cursor
    match_entry:
      ldy #vocab::name_offset
      jsr reset_pointer
      ldx #0

    next_char:
      lda (vocab::cursor),y
      beq end_entry     ; possible match, branch if zero terminator
      ; jsr input::read
    
      cmp (pointer,x)
      bne next_entry    ; no match
      jsr advance_pointer
      iny
      bne next_char

    next_entry: 
      jsr vocab::advance_cursor
      bne match_entry

    not_found:
      jmp die

    end_entry:
      lda (pointer,x)
      BraGe #33, next_entry
      jsr advance_offset 
      IMov result, cursor
      ldy #vocab::token_offset
      lda (cursor),y
      BraEq #bytecode::tCTL, write_ctl
      jmp write_run
  .endproc ; parse_entry

  .proc write_ctl
    RunFrom result
    rts
  .endproc

  .proc write
    WriteA writer
    rts
  .endproc  

  .proc write_int
    lda #bytecode::tINT
    jsr write
    jmp write_result
  .endproc

  .proc write_run
    lda #bytecode::tRUN
    jsr write
    jmp write_result
  .endproc

  .proc write_result 
    lda result
    jsr write
    lda result+1
    jsr write
    rts 
  .endproc

  .proc write_if
    lda #bytecode::tIF    
    jsr write
    lda #bytecode::tIF
    jsr write_hope
    rts
  .endproc

  .proc write_else
    lda #bytecode::tELSE
    jsr write

    ; TODO: check if tIF

    lda #bytecode::tIF
    ldy #2
    jsr resolve_hope
    bcs catch

    jsr cdrop

    lda #bytecode::tIF 
    jsr write_hope
    rts
    catch:
      jmp rmismatch
  .endproc

  .proc write_then
    
    lda #bytecode::tIF
    ldy #0
    jsr resolve_hope
    bcs catch

    jsr cdrop

    lda #bytecode::tTHEN
    jsr write
    rts
    catch:
      PrintName cTHEN
      jmp rmismatch
  .endproc

  .proc write_begin
    lda #bytecode::tBEGIN
    jsr write

    lda #bytecode::tBEGIN
    jsr store_ref
    rts
  .endproc

  .proc write_while
    lda #bytecode::tWHILE
    jsr write
    lda #bytecode::tWHILE
    jsr write_hope
    rts
  .endproc

  .proc write_again
    lda #bytecode::tAGAIN
    jsr write
    loop:
      lda #bytecode::tWHILE
      ldy #2
      jsr resolve_hope
      bcs not_while
      jsr cdrop
      jmp loop

      not_while:
      
      lda #bytecode::tBEGIN
      jsr write_ref
      jsr cdrop
      bcs catch
    rts
    catch:
      jmp rmismatch
  .endproc

  .proc write_hope
    jsr store_ref
    IAddB IP,2
    rts 
  .endproc

  .proc store_ref
    ldx csp 
    inx
    inx
    inx
    sta cstack-3,x
    lda IP
    sta cstack-2,x
    lda IP+1
    sta cstack-1,x
    stx csp
    rts 
  .endproc


  .proc resolve_hope
    ldx csp
    beq catch

    cmp cstack-3, x
    bne catch

    IMov temp, IP
    tya 
    IAddA temp
    Stash IP
      IMovIx IP, cstack-2,csp
      lda temp
      jsr write
      lda temp+1
      jsr write
    Unstash IP
    clc
    rts
    catch:
    sec
    rts
    temp: .word 0
  .endproc

  .proc write_ref
    ldx csp
    beq catch
    cmp cstack-3, x
    bne catch

    lda cstack-2, x
    jsr write
    lda cstack-1, x
    jsr write
    clc
    rts 
    catch:
    sec
    rts 
  .endproc

  .proc cdrop
    ldx csp
    txa
    beq catch
    dex
    dex
    dex
    stx csp
    rts 
    catch:
    jmp lmismatch
  .endproc
  
  .proc compile_skip_first
    ISet offset, BUF
    jsr reset_pointer
    jsr advance_pointer
    jsr advance_offset
    jmp do_compile
  .endproc

  .proc compile
  ISet offset, BUF
  .endproc  

  .proc do_compile
  ISet IP, HEAP_START
  CClear eof
  CClear error
  CClear csp
  Begin
    jsr skip_space
    BraTrue eof, break
    
    jsr parse_word
    BraTrue error, catch
  Again
  lda #bytecode::tRET
  jsr write
  lda #$12
  jsr write
  lda #$34
  jsr write
  
  lda csp
  bne rmismatch

  rts
  catch:
    jmp die
  exit:
    rts
  .endproc

  .proc die
    inc error
    rts
  .endproc 

  .proc lmismatch
    PrintChr ' '
    ColorSet 2
    lda csp
    jsr print::print_hex_digits
    PrintChr '('
    inc error
    rts
  .endproc

  .proc rmismatch
    PrintChr ' '
    ColorSet 2
    lda csp
    jsr print::print_hex_digits
    PrintChr ')'
    inc error
    rts
  .endproc
  .endscope
