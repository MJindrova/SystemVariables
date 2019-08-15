LPARAM m.lcOF
* lcOF - Output file


LOCAL m.lcPath, m.lcPom, m.lii, m.liCount, m.lihFile, m.liVFP, m.lcVFP, m.lcConfig
LOCAL ARRAY m.laRow(1), m.laType(1)
m.lcPath=SYS(16)
m.lcPath=IIF(RAT("\", m.lcPath)>0, LEFT(m.lcPath, RAT("\", m.lcPath)), m.lcPath)

m.liVFP=VAL(SUBS(VERSION(),LEN("Visual FoxPro ")+1,2))
m.lcVFP=IIF(m.liVFP<10, CHR(48+m.liVFP), CHR(55+m.liVFP))

IF EMPTY(m.lcOF)
   m.lcOF=m.lcPath+"..\out\"+PROGRAM()+"_"+m.lcVFP+".md"
ENDIF

m.lcConfig=m.lcPath+"VFP"+m.lcVFP+".list"
IF m.liVFP>6
   * Read config file
   m.lcPom=FILETOSTR(m.lcConfig)
   IF EMPTY(m.lcPom)
      ?"Config file is empty"
      RETURN
   ENDIF
   m.liCount=ALINES(m.laRow, m.lcPom)
ELSE
   m.lihFile=FOPEN(m.lcConfig)
   IF m.lihFile<=0 
      ?"Config file is empty"
      RETURN
   ENDIF
   m.liCount=0
   DO WHILE NOT FEOF(m.lihFile)
      m.liCount=m.liCount+1
      DIMENSION m.laRow(m.liCount)
      m.laRow(m.liCount)=FGETS(m.lihFile)
   ENDDO
   =FCLOSE(m.lihFile)
ENDIF


m.lihFile=FCREATE(m.lcOF)
IF m.lihFile<=0
   ?"Cannot create output file"
   RETURN
ENDIF

=ASORT(m.laRow)
DIME m.laType(m.liCount), m.laMax(m.liCount)
m.liMax=0
FOR m.lii=1 TO m.liCount
    m.laType(lii)=TYPE(m.laRow(m.lii))
NEXT

_TEXT=m.lihFile
SET CONSOLE OFF

SET TEXTMERGE ON
\\# System Variables in VFP <<m.lcVFP>>
\| Name  | Type | Value |
\|:------------- |:------------- |:------------- |

FOR m.lii=1 TO m.liCount
    IF m.laType(m.lii)#"U"
       m.lcPom=m.laType(m.lii)
       \| \<<m.laRow(m.lii)>> | <<m.laType(m.lii)>> | `<<IIF(m.lcPom="O", "Object", IIF(m.lcPom="C" AND EMPTY(EVAL(m.laRow(m.lii))), ' ', EVAL(m.laRow(m.lii))))>>` |
    ENDIF
NEXT
SET TEXTMERGE OFF


=FCLOSE(m.lihFile)
