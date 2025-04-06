 *PROYECTO ARQUITECTURA DE COMPUTADORES 2023

    ORG         $0
    DC.L        $8000           *Valor inicial del puntero de pila
    DC.L        PPAL            *Ppal
    
    ORG         $400

********************************************************************************************

*EQUIVALENCIAS

MR1A    EQU     $EFFC01         *De modo A (MR1A)
MR2A    EQU     $EFFC01         *De modo A (MR2A)
SRA     EQU     $EFFC03         *De estado A (SRA)
CSRA    EQU     $EFFC03         *De seleccion de reloj A (CSRA)
CRA     EQU     $EFFC05         *De control A (CRA)
RBA     EQU     $EFFC07         *Buffer recepcion A (RBA)
TBA     EQU     $EFFC07         *Buffer transmision A (TBA)
ACR     EQU     $EFFC09         *De control auxiliar (ACR)
ISR     EQU     $EFFC0B         *De estado de interrupcion (ISR)
IMR     EQU     $EFFC0B         *De mascara de interrupcion (IMR)
MR1B    EQU     $EFFC11         *De modo B (MR1B)
MR2B    EQU     $EFFC11         *De modo B (MR2B)
SRB     EQU     $EFFC13         *De estado (SRB)
CSRB    EQU     $EFFC13         *De seleccion de reloj B (CSRB)
CRB     EQU     $EFFC15         *De control B (CRB)
RBB     EQU     $EFFC17         *Buffer recepcion B (RBB)
TBB     EQU     $EFFC17         *Buffer transmision B (TBB)
IVR     EQU     $EFFC19         *De vector de interrupcion (IVR)

*********************************************************************************************

*RUTINA INIT

INIT:       MOVE.B  #%00010000,CRA          *Puntero MR1A (linea A) se reincia
            MOVE.B  #%00010000,CRB          *Puntero MR1B (linea B) se reincia
            MOVE.B  #%00000011,MR1A         *Configuracion de 8 bits por caracter para A
            MOVE.B  #%00000011,MR1B         *Configuracion de 8 bits por caracter para B
            MOVE.B  #%00000000,MR2A         *Desactivacion eco en A
            MOVE.B  #%00000000,MR2B         *Desactivacion eco en B
            MOVE.B  #%11001100,CSRA         *Se ajusta la velocidad de recepcion y transmision a 38400 bits por segundo
            MOVE.B  #%11001100,CSRB         *Se ajusta la velocidad de recepcion y transmision a 38400 bits por segundo
            MOVE.B  #%00000000,ACR
            MOVE.B  #%00000101,CRA          *Se activa la recepcion y la transmision en A
            MOVE.B  #%00000101,CRB          *Se activa la recepcion y la transmision en B
            MOVE.B  #%00100010,IMRCOPIA
            MOVE.B  IMRCOPIA,IMR            *Se habilita las interrupciones
            MOVE.B  #$40,IVR                *Se establece el vector de interrupcion, 40(hexadecimal)
            MOVE.L  #RTI,$100               *Se actualiza la direccion de la rutina de tratamiento de interrupcion, 100(hexadecimal)

            BSR     INI_BUFS                *llamada para iniciar los bufferes internos
            RTS


*RUTINA SCAN

SCAN:       LINK    A6,#0
            MOVE.L  8(A6),A1                *Direccion del buffer
            CLR.L   D1                      *Inicializacion a 0 del registro D1
            CLR.L   D2                      *Inicializacion a 0 del registro D2
            CLR.L   D3                      *Inicializacion a 0 del registro D3, contador
            MOVE.W  12(A6),D1               *En el registro D1 tenemos el descriptor
            MOVE.W  14(A6),D2               *En el D2 el tamaño

 SCANCOMP:  CMP.W   #0,D2                   *Se comprueba con el registro D2 el tamaño
            BEQ     SCANEND                 *Si el tamaño es cero se salta
            CMP.W   #0,D1                   *Se comprueba el descriptor de D1
            BEQ     SCANLA                  *Si la comparacion es exitosa, linea A
            CMP.W   #1,D1                   *Se comprueba el descriptor de D1
            BEQ     SCANLB                  *Si la comparacion es exitosa, linea B
            MOVE.L  #$FFFFFFFF,D0           *Error en la ejecucion
            BRA     SCANFIN

 SCANLA:    MOVE.L  #0,D0
            BRA     SCANBUCLE

 SCANLB:    MOVE.L  #1,D0
            BRA     SCANBUCLE

SCANBUCLE:  MOVEM.L D1-D3,-(A7)
            BSR     LEECAR
            MOVEM.L (A7)+,D1-D3
            CMP.L   #-1,D0                  *Se comprueba buffer
            BEQ     SCANEND                 *Acierto, se termina lectura, saltamos fin
            MOVE.B  D0,(A1)
            ADD.L   #1,A1
            ADD.L   #1,D3                   *Se incrementa el contador en uno
            SUB.W   #1,D2                   *Se decrementa el tamaño en uno
            BRA     SCANCOMP

 SCANEND:   MOVE.L  D3,D0                   *Se almacena el numero de caracteres que se han copiado en buffer

 SCANFIN:   UNLK    A6
            RTS
       

*RUTINA PRINT

PRINT:          LINK    A6,#0
                MOVE.L  8(A6),A1                *Direccion del buffer
                CLR.L   D2                      *Inicializacion a 0 del registro D2
                CLR.L   D3                      *Inicializacion a 0 del registro D3
                CLR.L   D4                      *Inicializacion a 0 del registro D4, contador
                MOVE.W  12(A6),D2               *En el registro D2 tenemos el descriptor
                MOVE.W  14(A6),D3               *En el registro D3 tenemos el tamaño
                CMP.W   #0,D2                   *Se comprueba el descriptor de D2
                BEQ     PRINTCOMP               *Se salta a bucle de comprobacion
                CMP.W   #1,D2                   *Se comprueba el descriptor de D2
                BEQ     PRINTCOMP               *Se salta a bucle de comprobacion
                MOVE.L  #$FFFFFFFF,D0           *Error en la ejecucion
                BRA     PRINTFIN

 PRINTCOMP:     CMP.W   #0,D2                   *Comprobacion linea
                BEQ     PRINTLA                 *Acierto, linea A
                CMP.W   #1,D2                   *Comprobacion linea
                BEQ     PRINTLB                 *Acierto, linea B

 PRINTLA:       MOVE.L  #2,D0
                CMP.W   #0,D3                   *Se comprueba el tamaño
                BEQ     PRINTC                  *Acierto, tamaño cero, por lo tanto saltamos
                MOVE.B  (A1)+,D1
                BSR     ESCCAR
                CMP.L   #-1,D0                  *Se comprueba el buffer
                BEQ     PRINTC                  *Acierto, buffer lleno
                ADD.L   #1,D4                   *Se incrementa el contador en uno
                SUB.W   #1,D3                   *Se decrementa el tamaño en uno
                BRA     PRINTCOMP


 PRINTLB:       MOVE.L  #3,D0
                CMP.W   #0,D3                   *Se comprueba el tamaño
                BEQ     PRINTC                  *Acierto, tamaño cero, por lo tanto saltamos
                MOVE.B  (A1)+,D1
                BSR     ESCCAR
                CMP.L   #-1,D0                  *Se comprueba el buffer
                BEQ     PRINTC                  *Acierto, buffer lleno
                ADD.L   #1,D4                   *Se incrementa el contador en uno
                SUB.W   #1,D3                   *Se decrementa el tamaño en uno
                BRA     PRINTCOMP


 PRINTC:        CMP.L   #0,D4                   *Se comprueba contador
                BEQ     PRINTEND                *Acierto, saltamos, no se ha escrito
                MOVE.W  SR,D5                   *Se almacena valor SR
                MOVE.W  #$2700,SR               *Se inhiben las interrupciones
                CMP.W   #0,D2                   *Se comprueba la linea
                BEQ     PRINTA                  *Acierto, linea A, se salta
                BSET    #4,IMRCOPIA
                BRA     PRINTCOP


 PRINTA:        BSET    #0,IMRCOPIA
                BRA     PRINTCOP


 PRINTCOP:      MOVE.B  IMRCOPIA,IMR
                MOVE.W  D5,SR                   *Se restaura valor original SR
                BRA     PRINTEND


 PRINTEND:      MOVE.L  D4,D0                *Se devuelve el numero de caracteres copiados en D0

 PRINTFIN:      UNLK    A6
                RTS


*RUTINA RTI

RTI:        MOVEM.L D0-D1,-(A7)

 RTIBUCLE:  MOVE.B  ISR,D1
            AND.B   IMRCOPIA,D1
            BTST    #1,D1               *Bit test 1 recepcion A
            BNE     RECA                *Si cumple, salta a recepcion
            BTST    #5,D1               *Bit test 5 recepcion B
            BNE     RECB                *Si cumple, salta a recepcion
            BTST    #0,D1               *Bit test 0 transmision A
            BNE     TRANSA              *Si cumple, salta a transmision
            BTST    #4,D1               *Bit test 4 transmision B
            BNE     TRANSB              *Si cumple, salta a transmision
            BRA     RTIFIN

 RECA:      MOVE.B  RBA,D1              *Caracter buffer recepcion A
            MOVE.L  #0,D0
            BSR     ESCCAR
            CMP.L   #-1,D0              *Se comprueba al buffer
            BEQ     RTIFIN              *Si esta lleno se salta
            BRA     RTIBUCLE

 TRANSA:    MOVE.L  #2,D0
            BSR     LEECAR
            CMP.L   #-1,D0              *Se comprueba al buffer
            BEQ     INTA                *Si esta vacio se salta
            MOVE.B  D0,TBA
            BRA     RTIBUCLE

 INTA:      BCLR    #0,IMRCOPIA         *Se inicializa a 0 el bit pos 0
            MOVE.B  IMRCOPIA,IMR        *Se actualiza el valor de IMR con IMRCOPIA
            BRA     RTIBUCLE

 RECB:      MOVE.B  RBB,D1              *Caracter buffer recepcion B
            MOVE.L  #1,D0
            BSR     ESCCAR
            CMP.L   #-1,D0               *Se comprueba al buffer
            BEQ     RTIFIN               *Si esta lleno se salta
            BRA     RTIBUCLE

 TRANSB:    MOVE.L  #3,D0
            BSR     LEECAR
            CMP.L   #-1,D0               *Se comprueba al buffer
            BEQ     INTB                 *Si esta vacio se salta
            MOVE.B  D0,TBB
            BRA     RTIBUCLE

 INTB:      BCLR    #4,IMRCOPIA         *Se inicializa a 0 el bit pos 4
            MOVE.B  IMRCOPIA,IMR        *Se actualiza el valor de IMR con IMRCOPIA
            BRA     RTIBUCLE

 RTIFIN:    MOVEM.L (A7)+,D0-D1         *Se restauran los registros
            RTE

IMRCOPIA    DS.B    1                   *IMR copia en memoria de las escrituras sobre dicho registro para lectura



*********************************************************************************************

*PROGRAMA PRINCIPAL

PPAL: BSR INIT

INCLUDE     bib_aux.s
