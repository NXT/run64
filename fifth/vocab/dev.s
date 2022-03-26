
DEF HDUMP
  _ HSTART
  _ DUMP
  _ DROP
END

DEF INCR, "INC"
  _ #1
  _ ADD
END

DEF TEST
  _ "COUNTDOWN"
  _ PRINT
  _ #10
  BEGIN
    _ DUP
    _ DEC
    _ #1
    _ SUB
    _ DUP
    _ DEC
  WHILE
  REPEAT
END 

DEF DUMP
_ DUP
_ #print::dump_hex
_ #print::arg
_ CALL1
_ #64
_ ADD
END

DEF TDUMP
  _ DUP
  _ #print::dump_text
  _ #print::arg
  _ CALL1
  _ #256
  _ ADD
END

PROC CR
  NewLine
  rts
END

DEF PRINT
  _ #print::print_z
  _ #print::arg
  _ CALL1
END

DEF CALL1
  _ ROT
  _ SET
  _ SYS
END

DEF VOCAB
  _ #vocab::bottom
  _ GET
END

DEF PSTART
  _ #PROG_START
END

DEF PEND
  _ #PROG_END
END 


DEF HSTART
  _ #HEAP_START
END

DEF HEND
  _ #HEAP_END
  _ GET
END

DEF HSIZE
  _ HEND
  _ HSTART
  _ SUB
END

DEF HCLEAR
  _ HEND
  _ HSTART
  _ SET
END 

PROC POKE
  Stash TMP
  SpLoad
  CopyTo 2,TMP
  GetLo 1
  
  ldy #0
  sta (TMP),y

  SpDec
  SpDec
  Unstash TMP
  rts 
END

PROC PEEK
  Stash TMP
  SpLoad
  CopyTo 1,TMP
  ldy #0
  lda (TMP),y
  InsertA 1
  Unstash TMP
  rts 
END


DEF H
  _ HSTART
  _ DLINE
  _ DLINE
  _ CR
END

DEF DLINE
  _ CR
  _ DUP
  _ HEX
  _ " "
  _ PRINT
  _ DUP
  _ PEEK
  _ DUP
  _ DEC
  _ DUP
  _ #bytecode::tRET
  _ EQ
  IF
    _ DROP 
    _ "RET"
    _ PRINT
    _ #0
    _
  ENDIF
  _ DUP
  _ #bytecode::tRUN
  _ EQ
  IF
    _ DROP
    _ INCR
    _ DUP
    _ GET
    _ #5
    _ ADD
    _ PRINT
    _ #2
    _ ADD
    _
  ENDIF
  _ DUP
  _ #bytecode::tIF
  _ EQ
  IF
    _ DROP
    _ "IF " 
    _ PRINT
    _ INCR
    _ GET
    _ HEX
    _ #2
    _ ADD
    _
  ENDIF
  _ DUP
  _ #bytecode::tPTR
  _ EQ
  IF
    _ DROP
    _ "PTR " 
    _ PRINT
    _ INCR
    _ GET
    _ HEX
    _ #2
    _ ADD
    _
  ENDIF
  _ DUP
  _ #bytecode::tINT
  _ EQ
  IF
    _ DROP
    _ "INT "
    _ PRINT
    _ #1
    _ ADD
    _ DUP
    _ GET
    _ DEC
    _ #2
    _ ADD
    _
  ENDIF
  _ "???"
  _ PRINT
END 
