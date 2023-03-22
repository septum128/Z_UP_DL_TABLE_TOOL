************************************************************************
* プログラムID : Z_UP_DL_TABLE_TOOL
* プログラム名 : テーブル一括DL/ULツール
* 機能内容     : テーブルの汎用DL/ULツール
* 注意事項     :
************************************************************************
REPORT /SH3/CAJX001010
  NO STANDARD PAGE HEADING
  MESSAGE-ID 00
  LINE-SIZE 170.

*----------------------------------------------------------------------*
* TABLES
*----------------------------------------------------------------------*
TABLES:
  T000,
  DD02L,
  DD02T,
  SSCRFIELDS.

*----------------------------------------------------------------------*
* INCLUDE
*----------------------------------------------------------------------*
INCLUDE:
  <ICON>.

*----------------------------------------------------------------------*
*  FIELD-SYMBOLS
*----------------------------------------------------------------------*
FIELD-SYMBOLS:
  <SCR_TXT>,                                "
  <TAB_DATA> TYPE STANDARD TABLE,           "TABLE DATA
  <TAB_LINE>,                               "HEADER LINE
  <TAB_ITEM>.                               "TABLE ITEM
*----------------------------------------------------------------------*
* TYPES
*----------------------------------------------------------------------*
* 動的選択
TYPE-POOLS
  RSDS.

* 動的項目選択
TYPES:
  BEGIN OF TYP_FIELD,
    TABNAME   TYPE TABNAME,
    FLD_RANGE TYPE RANGE OF FIELDNAME,
  END   OF TYP_FIELD.

TYPES:
* 汎用パラメータ用
  TY_R_CATSS01 TYPE RANGE OF RSDSSELOPT-LOW,

* テーブル一括UL ログテーブル
  TY_FIT00004   TYPE /SH3/FIT00004,
  TY_T_FIT00004 TYPE STANDARD TABLE OF TY_FIT00004.

*----------------------------------------------------------------------*
* GLOBAL DATA
*----------------------------------------------------------------------*
DATA:
* 透過テーブル項目情報
  T_DD03L      TYPE TABLE OF DFIES WITH HEADER LINE,
* 抽出条件(WHERE文自動生成)
  T_COND       TYPE TABLE OF WHERE_TAB,
* 抽出項目
  T_SELECT     TYPE TABLE OF WHERE_TAB,
* EXCEL DATA
  T_EXCEL      TYPE TABLE OF STRING WITH HEADER LINE,
* LINE DATA
  T_ITEM       TYPE TABLE OF STRING,
  H_ITEM       LIKE LINE  OF T_ITEM,
* F4 HELP
  T_DYNPFIELDS TYPE TABLE OF DYNPREAD WITH HEADER LINE,

* エラーメッセージ
  BEGIN OF T_ERR_MSG OCCURS 0,
    SEQ      TYPE I,
    ITEM(50) TYPE C,
    VAL(30)  TYPE C,
    MSG(100) TYPE C,
  END   OF T_ERR_MSG,

* 動的選択
  T_WHERE     TYPE RSDS_WHERE,
  T_FIELD     TYPE TYP_FIELD,
  W_CLNT_FLG  LIKE DD02L-CLIDEP,                 "CLNT依存FLAG
  W_LENGTH    LIKE DD03L-INTLEN,
  W_FPATH     LIKE FILE_TABLE-FILENAME,
  W_DATA_CNT  LIKE SY-DBCNT,
  W_ANSWER(1) TYPE C,
  W_TABIX     LIKE SY-TABIX,
  W_SPLIT     TYPE C,
  W_OVER      TYPE XFELD,

  REF_ITAB    TYPE REF TO DATA,
  REF_LINE    TYPE REF TO DATA.
*----------------------------------------------------------------------*
* GLOBAL CONSTANTS
*----------------------------------------------------------------------*
DATA:
  C_FUNC_CONV_IN  TYPE FUNCNAME VALUE 'CONVERSION_EXIT_?_INPUT',
  C_FUNC_CONV_OUT TYPE FUNCNAME VALUE 'CONVERSION_EXIT_?_OUTPUT',
  C_ON            TYPE XFELD    VALUE 'X',
  C_OFF           TYPE XFELD    VALUE ' ',
  C_CURR          TYPE DD03L-DATATYPE VALUE 'CURR',    "データ型(金額)
  C_WAERS_J       TYPE TCURC-WAERS    VALUE 'JPY'.     "日本円
*----------------------------------------------------------------------*
* PARAMETER SCREEN
*----------------------------------------------------------------------*
************************************************************************
* 処理選択
************************************************************************
SELECTION-SCREEN BEGIN OF BLOCK PARAM10 WITH FRAME TITLE TEXT010.

SELECTION-SCREEN  BEGIN  OF  LINE.
PARAMETERS
* ダウンロード
  RB_TE    RADIOBUTTON  GROUP  RAD1 USER-COMMAND SEL
                                              DEFAULT 'X'.
SELECTION-SCREEN     COMMENT    (12)  TEXT101 FOR FIELD RB_TE.
SELECTION-SCREEN  END    OF  LINE.
SELECTION-SCREEN  ULINE.

SELECTION-SCREEN  BEGIN  OF  LINE.
PARAMETERS
* アップロード
  RB_ET    RADIOBUTTON  GROUP  RAD1.
SELECTION-SCREEN     COMMENT    (12)  TEXT102 FOR FIELD RB_ET.
SELECTION-SCREEN  END    OF  LINE.
SELECTION-SCREEN  ULINE.

SELECTION-SCREEN  BEGIN  OF  LINE.
PARAMETERS
* データ削除
  RB_DEL   RADIOBUTTON  GROUP  RAD1.
SELECTION-SCREEN     COMMENT    (12)  TEXT103 FOR FIELD RB_DEL.
SELECTION-SCREEN  END    OF  LINE.
SELECTION-SCREEN END   OF BLOCK PARAM10.

************************************************************************
* 処理Option
************************************************************************
SELECTION-SCREEN BEGIN OF BLOCK PARAM20 WITH FRAME TITLE TEXT020.

**-- "Conversion Exit Option
SELECTION-SCREEN  BEGIN  OF  LINE.
PARAMETERS
   CB_EXIT  AS CHECKBOX MODIF ID OPT DEFAULT 'X'.
SELECTION-SCREEN     COMMENT    (18)  TEXT201 FOR FIELD CB_EXIT.
SELECTION-SCREEN  END    OF  LINE.

**-- "Conversion Currency Option
SELECTION-SCREEN  BEGIN  OF  LINE.
PARAMETERS
  CB_CHAN  AS CHECKBOX MODIF ID OPT DEFAULT 'X'.
SELECTION-SCREEN     COMMENT    (45)  TEXT211 FOR FIELD CB_CHAN.
SELECTION-SCREEN  END    OF  LINE.

**-- "UPLOAD Option
SELECTION-SCREEN  BEGIN  OF  LINE.
PARAMETERS
  CB_CHK   AS CHECKBOX MODIF ID OPT DEFAULT 'X'.
SELECTION-SCREEN     COMMENT    (18)  TEXT221 FOR FIELD CB_CHK.
SELECTION-SCREEN  END    OF  LINE.
SELECTION-SCREEN  BEGIN  OF  LINE.
PARAMETERS
  CB_LOG   AS CHECKBOX MODIF ID OPT DEFAULT 'X'.
SELECTION-SCREEN     COMMENT    (18)  TEXT223 FOR FIELD CB_LOG.
SELECTION-SCREEN  END    OF  LINE.

**-- "DELETE Option
SELECTION-SCREEN END   OF BLOCK PARAM20.

************************************************************************
* 透過テーブル情報
************************************************************************
SELECTION-SCREEN BEGIN OF BLOCK PARAM40 WITH FRAME TITLE TEXT040.

**-- ﾃｰﾌﾞﾙID
SELECTION-SCREEN  BEGIN  OF  LINE.
SELECTION-SCREEN     COMMENT   1(08)  TEXT401.
PARAMETERS:
  P_TSTR   LIKE  RSEDD0-DDOBJNAME,
  P_TNAME  LIKE  DD02T-DDTEXT  MODIF ID B7 VISIBLE LENGTH 39.
SELECTION-SCREEN     PUSHBUTTON (4)  TEXT408 USER-COMMAND FC01.
SELECTION-SCREEN  END    OF  LINE.
SELECTION-SCREEN  ULINE.
SELECTION-SCREEN  BEGIN OF   LINE.
SELECTION-SCREEN     COMMENT   1(12)  TEXT406.
SELECTION-SCREEN     POSITION  26.
PARAMETERS
  P_ROWS   TYPE  I.
SELECTION-SCREEN  END    OF  LINE.
SELECTION-SCREEN  BEGIN OF   LINE.
SELECTION-SCREEN     COMMENT   1(12)  TEXT407.
SELECTION-SCREEN     POSITION  26.
PARAMETERS
  P_COMMIT TYPE  I.
SELECTION-SCREEN  END    OF  LINE.
SELECTION-SCREEN END   OF BLOCK PARAM40.

************************************************************************
* ローカルファイル情報
************************************************************************
SELECTION-SCREEN BEGIN OF BLOCK PARAM30 WITH FRAME TITLE TEXT030.

** 列見出し
SELECTION-SCREEN  BEGIN  OF  LINE.
SELECTION-SCREEN     COMMENT   1(08)  TEXT301.
SELECTION-SCREEN     POSITION  15.
PARAMETERS
  RB_NASI  RADIOBUTTON  GROUP  G5.
SELECTION-SCREEN     COMMENT    (08)  TEXT302  FOR  FIELD RB_NASI.
SELECTION-SCREEN     POSITION  27.
PARAMETERS
  RB_ARI   RADIOBUTTON  GROUP  G5  DEFAULT  'X'.
SELECTION-SCREEN     COMMENT    (08)  TEXT303  FOR  FIELD RB_ARI.
SELECTION-SCREEN     POSITION  39.
PARAMETERS
  CB_FLD   AS CHECKBOX.
SELECTION-SCREEN     COMMENT    (18)  TEXT309  FOR  FIELD CB_FLD.
SELECTION-SCREEN  END    OF  LINE.

*** 区切り文字
SELECTION-SCREEN  BEGIN OF   LINE.
SELECTION-SCREEN     COMMENT   1(10)  TEXT304.
SELECTION-SCREEN     POSITION  15.
PARAMETERS
  RB_TAB   RADIOBUTTON  GROUP  G6.
SELECTION-SCREEN     COMMENT    (08)  TEXT305  FOR  FIELD RB_TAB.
SELECTION-SCREEN     POSITION  27.
PARAMETERS
  RB_CSV   RADIOBUTTON  GROUP  G6.
SELECTION-SCREEN     COMMENT    (08)  TEXT306  FOR  FIELD RB_CSV.
SELECTION-SCREEN     POSITION  39.
PARAMETERS
  RB_INP   RADIOBUTTON  GROUP  G6.
SELECTION-SCREEN     COMMENT    (08)  TEXT307  FOR  FIELD RB_INP.
SELECTION-SCREEN     POSITION  51.
PARAMETERS
  P_CHR    TYPE  CHAR1.
SELECTION-SCREEN  END   OF   LINE.
***
SELECTION-SCREEN  ULINE.

**-- ローカルファイル
SELECTION-SCREEN  BEGIN  OF  LINE.
SELECTION-SCREEN     COMMENT   1(08)  TEXT308.
PARAMETERS:
  P_DIR0   LIKE  RLGRAP-FILENAME,
  P_TYP    LIKE  RLGRAP-FILETYPE MODIF ID B7 DEFAULT 'ASC'.
SELECTION-SCREEN     PUSHBUTTON (04)  TEXT310 USER-COMMAND DEV.
SELECTION-SCREEN  END    OF  LINE.
SELECTION-SCREEN  BEGIN  OF  LINE.
SELECTION-SCREEN     POSITION  10.
PARAMETERS
  P_DIR1   LIKE  RLGRAP-FILENAME MODIF ID DR.
SELECTION-SCREEN  END    OF  LINE.
SELECTION-SCREEN  BEGIN  OF  LINE.
SELECTION-SCREEN     POSITION  10.
PARAMETERS
  P_DIR2   LIKE  RLGRAP-FILENAME MODIF ID DR.
SELECTION-SCREEN  END    OF  LINE.
SELECTION-SCREEN  BEGIN  OF  LINE.
SELECTION-SCREEN     POSITION  10.
PARAMETERS
  P_DIR3   LIKE  RLGRAP-FILENAME MODIF ID DR.
SELECTION-SCREEN  END    OF  LINE.
PARAMETERS
  P_FPATH  LIKE  FILE_TABLE-FILENAME NO-DISPLAY.
SELECTION-SCREEN END   OF BLOCK PARAM30.

************************************************************************
* 注意事項
************************************************************************
SELECTION-SCREEN BEGIN OF BLOCK PARAM90 WITH FRAME TITLE TEXT090.

**-- Download Comments
SELECTION-SCREEN  COMMENT  /1(78)  TEXT911 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT912 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT913 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT914 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT915 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT916 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT917 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT918 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT919 MODIF ID TX.
**-- Upload Comments
SELECTION-SCREEN  COMMENT  /1(78)  TEXT921 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT922 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT923 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT924 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT925 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT926 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT927 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT928 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT929 MODIF ID TX.

**-- Data Delete Comments
SELECTION-SCREEN  COMMENT  /1(78)  TEXT931 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT932 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT933 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT934 MODIF ID TX.
SELECTION-SCREEN  COMMENT  /1(78)  TEXT935 MODIF ID TX.
SELECTION-SCREEN END   OF BLOCK PARAM90.

**-- Functions --*******************************************************
SELECTION-SCREEN  FUNCTION KEY 1.           "Condition Select
SELECTION-SCREEN  FUNCTION KEY 2.           "Item Select
SELECTION-SCREEN  FUNCTION KEY 3.           "Count Check
SELECTION-SCREEN  FUNCTION KEY 5.           "Tr-cd:SE16

*&---------------------------------------------------------------------*
*&   マクロ
*&---------------------------------------------------------------------*
* 抽出項目の設定
DEFINE APPEND_SELECT.
  clear: t_select.
  t_select = &1.
  append t_select.
END-OF-DEFINITION.

* 選択画面：項目属性の設定
DEFINE MOD_SCR.
  if &2 = &3.
    screen-&1     = 0.                      "非表示/入力不可...
  else.
    screen-&1     = 1.                      "表示/入力可...
  endif.
END-OF-DEFINITION.

*----------------------------------------------------------------------*
* INITIALIZATION
*----------------------------------------------------------------------*
INITIALIZATION.

* 初期処理
  PERFORM INITIAL.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN OUTPUT
*----------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

* 画面項目の入力属性の設定
  PERFORM EDIT_SCREEN.

* テーブル名称取得
  PERFORM STR_NAME_GET:
    USING 'S'  P_TSTR  'P_TSTR'   P_TNAME.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN ON
*----------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_TSTR.
* 透過ﾃｰﾌﾞﾙ構造体検索ヘルプ
  PERFORM  F4_HELP1 USING  P_TSTR.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_DIR0.
* PCファイル名検索ヘルプ
  PERFORM  F4_HELP3 USING  P_DIR0 'P_DIR0'.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.

* チェック: 各種選択条件
  PERFORM CHECK_PARA.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

* 実行時の初期処理
  PERFORM INIT.

* 対象テーブルの構造、属性等のチェック
  PERFORM STRUCT_CHK
    USING
      P_TSTR.                               "[i]WK: テーブルID

* 選択条件: 処理選択別
  CASE C_ON.
*   ダウンロード
    WHEN RB_TE.
      PERFORM HEAD_CREATE.                  "列見出し作成
      PERFORM EXCEL_CREATE.                 "ダウンロードデータ作成
      PERFORM EXCEL_DOWNLOAD.               "ファイルダウンロード

*   アップロード
    WHEN RB_ET.
      PERFORM EXCEL_UPLOAD.                 "ファイルアップロード
      PERFORM UPF_CREATE.                   "更新データ作成
      PERFORM TABLE_UPDATE.                 "テーブル更新
      PERFORM UPLOAD_LOG.                   "エラーログ出力

*   データ削除
    WHEN RB_DEL.
      PERFORM TABLE_DELETE.                 "テーブルデータ削除
  ENDCASE.

*----------------------------------------------------------------------*
* TOP-OF-PAGE
*----------------------------------------------------------------------*
TOP-OF-PAGE.

  IF RB_ET = C_ON.                          "IF: アップロード処理時
    WRITE: /001(008)  ' 行番号 ',
            011(020)  ' 項目名',
            035(020)  ' 入力値',
            060(020)  ' エラーメッセージ'.
    ULINE.
  ENDIF.

*----------------------------------------------------------------------*
*   END-OF-SELECTION
*----------------------------------------------------------------------*
END-OF-SELECTION.

  IF T_WHERE IS INITIAL.
    FREE MEMORY ID 'COND_WHERE'.
  ELSE.
    EXPORT T_WHERE TO MEMORY ID 'COND_WHERE'.
  ENDIF.

  IF T_FIELD IS INITIAL.
    FREE MEMORY ID 'SELECT_ITEM'.
  ELSE.
    EXPORT T_FIELD TO MEMORY ID 'SELECT_ITEM'.
  ENDIF.

************************************************************************
* FORMS 以下プログラム毎のFORM文
************************************************************************
*&---------------------------------------------------------------------*
*&      Form  INITIAL
*&---------------------------------------------------------------------*
*       初期処理
*----------------------------------------------------------------------*
FORM INITIAL .

* 選択画面テキスト設定
  PERFORM SET_DYNPRO_TEXT.

* 押ボタンテキスト設定
  PERFORM SET_FUNCTION_TEXT:
          USING '範囲選択'   ICON_SELECT_WITH_CONDITION '' ''
       CHANGING SSCRFIELDS-FUNCTXT_01,
          USING '項目選択'   ICON_CHOOSE_COLUMNS '' ''
       CHANGING SSCRFIELDS-FUNCTXT_02,
          USING 'エントリ数' '' '' ''
       CHANGING SSCRFIELDS-FUNCTXT_03,
          USING 'テーブル内容' ICON_LIST '' ''
       CHANGING SSCRFIELDS-FUNCTXT_05.

  P_COMMIT = 10000.
  CLEAR: W_FPATH.

  IMPORT T_WHERE FROM MEMORY ID 'COND_WHERE'.
  IMPORT T_FIELD FROM MEMORY ID 'SELECT_ITEM'.
  FREE: MEMORY ID 'COND_WHERE',
        MEMORY ID 'SELECT_ITEM'.

ENDFORM.                    " INITIAL
*&---------------------------------------------------------------------*
*&      選択画面テキスト設定
*&---------------------------------------------------------------------*
FORM SET_DYNPRO_TEXT .
*           '----+----1----+----2----+----3----+----4----+----5----+---'
  TEXT010 = '処理選択'.
  TEXT020 = '処理Option'.
  TEXT030 = 'ローカルファイル情報'.
  TEXT040 = '透過テーブル情報'.
  TEXT090 = '注意事項'.
  TEXT101 = 'ダウンロード'.
  TEXT102 = 'アップロード'.
  TEXT103 = 'データ削除'.
  TEXT201 = '変換Exit適用'.
  TEXT211 = '通貨の書式変換(外部-内部)JPYのみ対応'.
  TEXT221 = 'データチェックのみ'.
  TEXT223 = 'ログ出力'.
  TEXT301 = '列見出し'.
  TEXT302 = 'なし'.
  TEXT303 = 'あり'.
  TEXT304 = '区切り文字'.
  TEXT305 = 'タブ'.
  TEXT306 = 'CSV(ｶﾝﾏ)'.
  TEXT307 = 'その他'.
  TEXT308 = 'ファイル名'.
  TEXT309 = '「項目名」付き'.
  TEXT310 = ICON_EXPAND.
  TEXT401 = 'テーブルID'.
  TEXT406 = '最大該当数'.
  TEXT407 = 'コミット単位'.
  TEXT408 = ICON_ENTER_MORE.

* ダウンロード用コメント
  TEXT911 = '①列見出し‘あり’を選択すると一行目に項目テキストを' &
            '出力します。'.
  TEXT912 = '　更に‘「項目名」付き’を選択すると、項目名の行が' &
            '追加されます。'.
  TEXT913 = '②区切り文字と同一の項目値は空白に置換後、出力されます。'.
  TEXT914 = '③最大該当数がゼロの場合、対象範囲全体を出力します。'.

* アップロード用コメント
  TEXT921 = '①列見出し‘あり’を選択すると一行目の内容は無効です。'.
  TEXT922 = '　テーブルの項目値は区切られた順に設定します。'.
  TEXT923 = '②「項目名」付きを選択すると二行目の項目名が一致した' &
            '列のみ'.
  TEXT924 = '　テーブルの項目値を設定します。'.
  TEXT925 = '③セル値に区切り文字と同一の値があると、結果は保証' &
            'できません。'.
  TEXT926 = '④数量項目の書式変換(外部-内部)は' &
            '対応していません。'.
  TEXT931 = '①削除完了後に「コミット」が実行されます。'.
  TEXT932 = '　「ロールバック」は出来ませんので、ご注意下さい！'.
  TEXT933 = ''.
*           '----+----1----+----2----+----3----+----4----+----5----+---'

ENDFORM.                    "SET_DYNPRO_TEXT
*&---------------------------------------------------------------------*
*&      Form  CHECK_PARA
*&---------------------------------------------------------------------*
*       チェック: 各種選択条件
*----------------------------------------------------------------------*
FORM CHECK_PARA .

  IF    P_TSTR(5) = '/SH3/'                 "IF: テーブルID 先頭5桁
    OR  P_TSTR(1) = 'Z'                     "IF: テーブルID 先頭1桁
    OR  P_TSTR(1) = 'Y'                     "IF: テーブルID 先頭1桁
    OR  P_TSTR    = SPACE.                  "IF: テーブルID ブランク

  ELSE.
    IF   RB_ET  = 'X'                       "IF: 処理選択 アップロード
      OR RB_DEL = 'X'.                      "IF: 処理選択 データ削除

      PERFORM POPUP_TO_CONFIRM
        USING
          '対象テーブル確認'
          '標準テーブルです。'
          '本当に更新しますか？'
          '2'
          'W'
        CHANGING
          W_ANSWER.

      IF W_ANSWER <> '1'.
        SET CURSOR FIELD 'P_TSTR'.
        MESSAGE S398 DISPLAY LIKE 'E'
                WITH '処理を中止しました' '' '' ''.
        STOP.
      ENDIF.

*      SET CURSOR FIELD 'P_TSTR'.
*      MESSAGE E398 WITH 'アドオンテーブルのみ指定できます' '' '' ''.
    ENDIF.
  ENDIF.

  IF SY-BATCH IS NOT INITIAL.
    MESSAGE E398 WITH 'バックグラウンド実行は行なえません' '' '' ''.
  ENDIF.

* 選択画面の処理選択がアップロード、または、
* 選択画面の処理選択がデータ削除の場合
  IF RB_ET  = 'X'
  OR RB_DEL = 'X'.
*   更新・削除対象外のチェック
    PERFORM CHECK_CAT0001.
  ENDIF.

  CASE SSCRFIELDS-UCOMM.
    WHEN 'SEL'.                             "処理選択
      IF RB_ET = C_ON.
        CB_CHK = CB_LOG = C_ON.
      ENDIF.
      EXIT.
    WHEN 'DEV'.                             "ファイル名入力欄拡張
      IF TEXT310 = ICON_EXPAND.
        TEXT310 = ICON_COLLAPSE.
      ELSE.
        TEXT310 = ICON_EXPAND.
      ENDIF.
      CLEAR: SSCRFIELDS-UCOMM.
      EXIT.
    WHEN OTHERS.
  ENDCASE.

* テーブル名Check
  IF P_TSTR IS INITIAL.
    CLEAR: SSCRFIELDS-UCOMM.
    SET CURSOR FIELD 'P_TSTR'.
    MESSAGE E410(MO).

  ELSE.

*   テーブル名称取得
    PERFORM STR_NAME_GET:   USING 'E'  P_TSTR  'P_TSTR'   P_TNAME.

    IF T_WHERE-TABLENAME <> P_TSTR.
      FREE: T_WHERE.
    ENDIF.

    IF T_FIELD-TABNAME <> P_TSTR.
      FREE: T_FIELD.
    ENDIF.

  ENDIF.

* ユーザーコマンド処理
  IF SSCRFIELDS-UCOMM CP 'FC*'.
    PERFORM USER_COMMAND USING SSCRFIELDS-UCOMM.
    CLEAR: SSCRFIELDS-UCOMM.
  ENDIF.

* アップロード時の列見出しチェック
  IF RB_ET = C_ON.
    IF RB_NASI = C_ON AND CB_FLD = C_ON.
      SET CURSOR FIELD 'CB_FLD'.
      MESSAGE E398 WITH
      '列見出し：なしを選択した場合、'
      '「項目名」付きを指定できません' '' ''.
    ENDIF.
  ENDIF.

  P_ROWS   = ABS( P_ROWS ).                 "絶対値
  P_COMMIT = ABS( P_COMMIT ).               "絶対値

  CHECK SSCRFIELDS-UCOMM = 'ONLI'.

* Commit数Check
  IF RB_ET = C_ON AND P_COMMIT IS INITIAL.
    CLEAR: SSCRFIELDS-UCOMM.
    SET CURSOR FIELD 'P_COMMIT'.
    MESSAGE E055.
  ENDIF.

* 区切り文字Check
  IF RB_INP = C_ON AND P_CHR IS INITIAL.
    CLEAR: SSCRFIELDS-UCOMM.
    SET CURSOR FIELD 'P_CHR'.
    MESSAGE E055.
  ENDIF.

* ローカルファイルCheck
  IF RB_DEL IS INITIAL.
    IF P_DIR0 IS NOT INITIAL.
*      W_FPATH = P_DIR0.
      CONCATENATE P_DIR0 P_DIR1 P_DIR2 P_DIR3
             INTO W_FPATH.
    ELSEIF P_FPATH IS NOT INITIAL.
      W_FPATH = P_FPATH.
    ELSE.
*    IF P_DIR0 IS INITIAL.
      CLEAR: SSCRFIELDS-UCOMM.
      SET CURSOR FIELD 'P_DIR0'.
      MESSAGE E055.
    ENDIF.
  ENDIF.

  CASE C_ON.
    WHEN RB_TE.
*     ディレクトリ存在チェック
      PERFORM CHECK_EXIST_FILE USING 'D' W_FPATH
                            CHANGING W_ANSWER.
    WHEN RB_ET.
*     PCファイル名存在チェック
      PERFORM CHECK_EXIST_FILE USING 'F' W_FPATH
                            CHANGING W_ANSWER.
    WHEN RB_DEL.
      W_ANSWER = C_ON.
  ENDCASE.

  IF W_ANSWER <> C_ON.
    CLEAR: SSCRFIELDS-UCOMM, W_FPATH.
    SET CURSOR FIELD 'P_DIR0'.
    IF RB_ET = C_ON.
      MESSAGE S398 DISPLAY LIKE 'E'
              WITH 'ファイル名(PC)が存在しません' '' '' ''.
    ELSE.
      MESSAGE S398 DISPLAY LIKE 'E'
              WITH 'ディレクトリが存在しません' '' '' ''.
    ENDIF.
    STOP.
  ENDIF.

ENDFORM.                    " CHECK_PARA
*&---------------------------------------------------------------------*
*&      押ボタンテキスト設定
*&---------------------------------------------------------------------*
*      -->PI_TEXT    機能テキスト
*      -->PI_ICONID  アイコン
*      -->PI_ICONTX  アイコンテキスト
*      -->PI_QINFO   情報テキスト
*      <--PO_FUNCTX  押ボタン用テキスト
*----------------------------------------------------------------------*
FORM SET_FUNCTION_TEXT USING PI_TEXT   TYPE C
                             PI_ICONID TYPE C
                             PI_ICONTX TYPE C
                             PI_QINFO  TYPE C
                    CHANGING PO_FUNCTX TYPE RSFUNC_TXT.

  DATA: LW_DYNTXT   LIKE SMP_DYNTXT.

  LW_DYNTXT-TEXT      = PI_TEXT.
  LW_DYNTXT-ICON_ID   = PI_ICONID.
  LW_DYNTXT-ICON_TEXT = PI_ICONTX.
  LW_DYNTXT-QUICKINFO = PI_QINFO.
  PO_FUNCTX = LW_DYNTXT.

ENDFORM.                    "SET_FUNCTION_TEXT
*&---------------------------------------------------------------------*
*&      選択画面項目の属性設定
*&---------------------------------------------------------------------*
FORM EDIT_SCREEN.

  LOOP AT SCREEN.
    CASE SCREEN-GROUP1.
      WHEN 'TX'.
        ASSIGN (SCREEN-NAME) TO <SCR_TXT>.
        IF <SCR_TXT> IS INITIAL.
          SCREEN-ACTIVE = 0.                     "非表示
        ELSE.
          IF ( RB_TE  = C_ON AND SCREEN-NAME CP 'TEXT91+' )
          OR ( RB_ET  = C_ON AND SCREEN-NAME CP 'TEXT92+' )
          OR ( RB_DEL = C_ON AND SCREEN-NAME CP 'TEXT93+' ).
            SCREEN-ACTIVE = 1.                   "表示
          ELSE.
            SCREEN-ACTIVE = 0.                   "非表示
          ENDIF.
        ENDIF.
      WHEN 'B7'.
        SCREEN-INPUT  = 0.                       "入力不可
      WHEN 'DR'.
        MOD_SCR ACTIVE TEXT310 ICON_EXPAND.
      WHEN 'OPT'.
        CASE SCREEN-NAME.
          WHEN 'CB_EXIT'.
            MOD_SCR INPUT RB_DEL C_ON.
          WHEN 'CB_CHAN'.
            MOD_SCR INPUT RB_ET  C_OFF.
            MOD_SCR INPUT RB_DEL C_ON.
          WHEN 'CB_CHK' OR 'CB_LOG'.
            MOD_SCR INPUT RB_ET  C_OFF.
        ENDCASE.
      WHEN OTHERS.
        CASE SCREEN-NAME.
          WHEN 'TEXT408'.
            IF T_WHERE-WHERE_TAB[] IS INITIAL.
              TEXT408 = ICON_ENTER_MORE.
            ELSE.
              TEXT408 = ICON_DISPLAY_MORE.
            ENDIF.
          WHEN 'P_ROWS'   OR 'TEXT406'.
            MOD_SCR ACTIVE RB_TE C_OFF.
          WHEN 'P_COMMIT' OR 'TEXT407'.
            MOD_SCR ACTIVE RB_TE C_ON.
            MOD_SCR INPUT  RB_ET C_OFF.
        ENDCASE.
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.

ENDFORM.                    " EDIT_SCREEN
*&---------------------------------------------------------------------*
*&      テーブル名称取得
*&---------------------------------------------------------------------*
*      -->PI_TABNAME  テーブル名
*      <--PO_DDTEXT   テーブル名称
*----------------------------------------------------------------------*
FORM STR_NAME_GET USING PI_MSGTY   LIKE SY-MSGTY
                        PI_TABNAME TYPE ANY
                        PI_FLDNAME TYPE ANY
                        PO_DDTEXT  TYPE ANY.

  CLEAR: W_CLNT_FLG, PO_DDTEXT.
  IF  NOT PI_TABNAME  IS INITIAL.
    SELECT  SINGLE A~CLIDEP  B~DDTEXT                       "#EC *
            FROM  DD02L AS A INNER JOIN DD02T AS B
            ON    A~TABNAME     =  B~TABNAME
            AND   A~AS4LOCAL    =  B~AS4LOCAL
            INTO (W_CLNT_FLG, PO_DDTEXT)
            WHERE A~TABNAME     =  PI_TABNAME
            AND   A~AS4LOCAL    =  'A'
            AND   B~DDLANGUAGE  =  SY-LANGU.
    IF SY-SUBRC = 0.
    ELSE.
      CLEAR: SSCRFIELDS-UCOMM.
      SET CURSOR FIELD PI_FLDNAME.
      IF PI_MSGTY = 'E'.
        MESSAGE ID 'MO' TYPE PI_MSGTY NUMBER '402'
                        WITH PI_TABNAME.
      ELSE.
        MESSAGE ID 'MO' TYPE PI_MSGTY NUMBER '402' DISPLAY LIKE 'E'
                        WITH PI_TABNAME.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    " STR_NAME_GET

*&---------------------------------------------------------------------*
*&      テーブル名検索HELP
*&---------------------------------------------------------------------*
*      <--PO_TABNAME  テーブル名
*----------------------------------------------------------------------*
FORM  F4_HELP1 USING PO_TABNAME TYPE TABNAME.

  DATA: LW_SELOBJ LIKE RSEDD0-DDOBJNAME.

**-- Dynpro項目値の読込
  PERFORM  DYNP_READ USING 'P_TSTR'.

  CALL FUNCTION 'RS_DD_F4_OBJECT'
    EXPORTING
      OBJNAME            = PO_TABNAME
      OBJTYPE            = 'T'
      SUPPRESS_SELECTION = 'X'
    IMPORTING
      SELOBJNAME         = LW_SELOBJ.
  IF LW_SELOBJ IS NOT INITIAL.
    MOVE LW_SELOBJ TO PO_TABNAME.
  ENDIF.

ENDFORM.                                                    " F4_HELP1
*&---------------------------------------------------------------------*
*&      ファイル名検索HELP
*&---------------------------------------------------------------------*
*      <--PO_FILE  ファイル名
*----------------------------------------------------------------------*
FORM  F4_HELP3 USING PO_FILE TYPE ANY
                     PI_FNAM TYPE DYNFNAM.

  FIELD-SYMBOLS: <FS_FNAM>.
  DATA: L_SET_FILE_NM TYPE FILETABLE,
        LT_FILE_TABLE TYPE FILETABLE,
        LH_FILE_TABLE LIKE LINE OF LT_FILE_TABLE,
        LW_FNAM       TYPE DYNFNAM,
        LW_CNT        TYPE N,
        LW_FILE       TYPE RLGRAP-FILENAME,
        LW_FILE_DEF   TYPE STRING,
        LW_DIR_DEF    TYPE STRING,
        LW_RC         TYPE I,
        LW_INP_LEN    TYPE I,
        LW_MAX_LEN    TYPE I.

**-- Dynpro項目値の読込
  CLEAR: LW_CNT, LH_FILE_TABLE-FILENAME.
  DO 4 TIMES.
    CONCATENATE 'P_DIR' LW_CNT INTO LW_FNAM.
    ASSIGN (LW_FNAM) TO <FS_FNAM>.
    IF <FS_FNAM> IS ASSIGNED.
      PERFORM  DYNP_READ USING LW_FNAM.
      IF LH_FILE_TABLE-FILENAME IS INITIAL.
        LH_FILE_TABLE-FILENAME = <FS_FNAM>.
      ELSE.
        CONCATENATE LH_FILE_TABLE-FILENAME <FS_FNAM>
               INTO LH_FILE_TABLE-FILENAME.
      ENDIF.
    ENDIF.
    ADD 1 TO LW_CNT.
  ENDDO.

  IF LH_FILE_TABLE-FILENAME IS NOT INITIAL.
    PERFORM SPLIT_FILE_AND_PATH USING LH_FILE_TABLE-FILENAME
                             CHANGING LW_FILE_DEF
                                      LW_DIR_DEF.
  ENDIF.
*
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_OPEN_DIALOG
    EXPORTING
      WINDOW_TITLE            = 'ローカルPCファイル'
      DEFAULT_FILENAME        = LW_FILE_DEF
      INITIAL_DIRECTORY       = LW_DIR_DEF
    CHANGING
      FILE_TABLE              = L_SET_FILE_NM
      RC                      = LW_RC
    EXCEPTIONS
      FILE_OPEN_DIALOG_FAILED = 1
      CNTL_ERROR              = 2
      ERROR_NO_GUI            = 3
      NOT_SUPPORTED_BY_GUI    = 4
      OTHERS                  = 5.

* *--- 例外処理
  CASE SY-SUBRC.
    WHEN 0.
    WHEN OTHERS.
      MESSAGE S398 DISPLAY LIKE 'E'
                   WITH 'FILE_OPEN_DIALOG_ERROR' '(RC=' SY-SUBRC ')'.
  ENDCASE.

*--- ファイル名取得
  CHECK NOT LW_RC IS INITIAL
  AND   NOT LW_RC = '-1'.
* 入力ファイル名の読み込み
  LT_FILE_TABLE[] = L_SET_FILE_NM.
  READ TABLE LT_FILE_TABLE INTO LH_FILE_TABLE INDEX 1.
  CHECK SY-SUBRC = 0
    AND NOT LH_FILE_TABLE-FILENAME IS INITIAL.

  CLEAR: LW_CNT, LW_MAX_LEN.
  PERFORM DYNP_UPDATE USING 'I' '' ''.
  DO 4 TIMES.
    CLEAR: LW_FILE.
    CONCATENATE 'P_DIR' LW_CNT INTO LW_FNAM.
    ASSIGN (LW_FNAM) TO <FS_FNAM>.
    IF <FS_FNAM> IS ASSIGNED.
      DESCRIBE FIELD <FS_FNAM> LENGTH LW_INP_LEN IN BYTE MODE.
      PERFORM TEXT_SPLIT USING LH_FILE_TABLE-FILENAME 0 '\'
                      CHANGING LW_FILE LH_FILE_TABLE-FILENAME.
      PERFORM DYNP_UPDATE USING 'S' LW_FNAM LW_FILE.
      ADD LW_INP_LEN TO LW_MAX_LEN.
    ENDIF.
    ADD 1 TO LW_CNT.
  ENDDO.

  IF LH_FILE_TABLE-FILENAME IS INITIAL.
    PERFORM DYNP_UPDATE USING 'U' '' ''.
  ELSE.
    LW_MAX_LEN = LW_MAX_LEN * 4.
    MESSAGE S398 DISPLAY LIKE 'E'
            WITH 'Directory及びFile名が長過ぎます'
                 '(MAX:' LW_MAX_LEN 'Byte)'.
  ENDIF.

ENDFORM.                                                    " F4_HELP3
*&---------------------------------------------------------------------*
*&      Dynpro項目値の読込
*&---------------------------------------------------------------------*
*      -->PI_DYNFNAM  Dynpro項目名
*----------------------------------------------------------------------*
FORM DYNP_READ USING PI_DYNFNAM TYPE DYNFNAM.

  FIELD-SYMBOLS <FS_DYNFNAM> TYPE ANY.

  CLEAR:   T_DYNPFIELDS.
  REFRESH: T_DYNPFIELDS.
  MOVE  PI_DYNFNAM         TO  T_DYNPFIELDS-FIELDNAME.
  APPEND  T_DYNPFIELDS.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      DYNAME               = SY-CPROG      "
      DYNUMB               = SY-DYNNR      "
    TABLES
      DYNPFIELDS           = T_DYNPFIELDS
    EXCEPTIONS
      INVALID_ABAPWORKAREA = 1
      INVALID_DYNPROFIELD  = 2
      INVALID_DYNPRONAME   = 3
      INVALID_DYNPRONUMMER = 4
      INVALID_REQUEST      = 5
      NO_FIELDDESCRIPTION  = 6
      INVALID_PARAMETER    = 7
      UNDEFIND_ERROR       = 8
      DOUBLE_CONVERSION    = 9
      STEPL_NOT_FOUND      = 10
      OTHERS               = 11.

  IF SY-SUBRC = 0.
    READ TABLE T_DYNPFIELDS INDEX 1.
    ASSIGN (T_DYNPFIELDS-FIELDNAME) TO <FS_DYNFNAM>.
    MOVE T_DYNPFIELDS-FIELDVALUE TO <FS_DYNFNAM>.
  ENDIF.

ENDFORM.                    " DYNP_READ
*&---------------------------------------------------------------------*
*&      Dynpro項目内容変更
*&---------------------------------------------------------------------*
*      -->PI_DYNFNAM  Dynpro項目名
*      -->PI_DYNFVAL  Dynpro項目値
*----------------------------------------------------------------------*
FORM DYNP_UPDATE USING PI_PRCMD   TYPE C
                       PI_DYNFNAM TYPE DYNFNAM
                       PI_DYNFVAL TYPE ANY.

  IF PI_PRCMD CA 'I'.
    CLEAR:   T_DYNPFIELDS.
    REFRESH: T_DYNPFIELDS.
  ENDIF.

  IF PI_PRCMD CA 'S'.
    MOVE   PI_DYNFNAM   TO  T_DYNPFIELDS-FIELDNAME.
    MOVE   PI_DYNFVAL   TO  T_DYNPFIELDS-FIELDVALUE.
    APPEND  T_DYNPFIELDS.
  ENDIF.

  CHECK PI_PRCMD CA 'U'.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      DYNAME               = SY-CPROG
      DYNUMB               = SY-DYNNR
    TABLES
      DYNPFIELDS           = T_DYNPFIELDS
    EXCEPTIONS
      INVALID_ABAPWORKAREA = 1
      INVALID_DYNPROFIELD  = 2
      INVALID_DYNPRONAME   = 3
      INVALID_DYNPRONUMMER = 4
      INVALID_REQUEST      = 5
      NO_FIELDDESCRIPTION  = 6
      UNDEFIND_ERROR       = 7
      OTHERS               = 8.

  IF SY-SUBRC <> 0.
    MESSAGE S398 DISPLAY LIKE 'E'
                 WITH 'DYNP_VALUES_UPDATE_ERROR' '(RC=' SY-SUBRC ')'.
  ENDIF.

ENDFORM.                    " DYNP_UPDATE
*&---------------------------------------------------------------------*
*&      PCファイル名存在チェック
*&---------------------------------------------------------------------*
*      -->PI_PRCMD   MODE("D":Directory / "F":File)
*      -->PI_PCFILE  PCファイル名
*      <--PO_RESULT  戻り値
*----------------------------------------------------------------------*
FORM CHECK_EXIST_FILE USING PI_PRCMD  TYPE CHAR01
                            PI_PCFILE TYPE ANY
                   CHANGING PO_RESULT TYPE CHAR01.

  DATA: LW_FILENAM TYPE STRING,
        LW_PATH    TYPE STRING.

  CLEAR: PO_RESULT.

  IF PI_PRCMD = 'D'.
*   パスとファイル名への分割
    PERFORM SPLIT_FILE_AND_PATH USING PI_PCFILE
                             CHANGING LW_FILENAM
                                      LW_PATH.
    IF SY-SUBRC <> 0.
      EXIT.
    ENDIF.
*   ディレクトリ存在チェック
    CALL METHOD CL_GUI_FRONTEND_SERVICES=>DIRECTORY_EXIST
      EXPORTING
        DIRECTORY            = LW_PATH
      RECEIVING
        RESULT               = PO_RESULT
      EXCEPTIONS
        CNTL_ERROR           = 1
        ERROR_NO_GUI         = 2
        WRONG_PARAMETER      = 3
        NOT_SUPPORTED_BY_GUI = 4
        OTHERS               = 5.
    IF SY-SUBRC <> 0.
      EXIT.
    ENDIF.

  ELSEIF PI_PRCMD = 'F'.
    LW_FILENAM = PI_PCFILE.
* ファイル存在チェック
    CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_EXIST
      EXPORTING
        FILE                 = LW_FILENAM
      RECEIVING
        RESULT               = PO_RESULT
      EXCEPTIONS
        CNTL_ERROR           = 1
        ERROR_NO_GUI         = 2
        WRONG_PARAMETER      = 3
        NOT_SUPPORTED_BY_GUI = 4
        OTHERS               = 5.

    IF SY-SUBRC <> 0.
      EXIT.
    ENDIF.
  ENDIF.

ENDFORM.                    " CHECK_EXIST_FILE
*&---------------------------------------------------------------------*
*&      パスとファイル名への分割
*&---------------------------------------------------------------------*
*      -->PI_FULLNAME   完全ファイル名
*      <--PO_FILENAME   ファイル名
*      <--PO_DIRECTORY  ファイルパス
*----------------------------------------------------------------------*
FORM SPLIT_FILE_AND_PATH USING PI_FULLNAME  TYPE ANY
                      CHANGING PO_FILENAME  TYPE ANY
                               PO_DIRECTORY TYPE ANY.

  DATA: LW_EXTENSION TYPE FILE_TABLE-FILENAME.

* Copied from DSVAS_DOC_FILENAME_SPLIT --- START
  DATA: LF_FULLNAME TYPE FILE_TABLE-FILENAME,
        LF_FILENAME TYPE FILE_TABLE-FILENAME,
        LF_DIRLEN   TYPE I.

  LF_FULLNAME = PI_FULLNAME.
  CLEAR: PO_DIRECTORY, PO_FILENAME, LW_EXTENSION.

* Dateiname suchen
  WHILE LF_FULLNAME CA ':\/'.
    ADD 1 TO SY-FDPOS.
    ADD SY-FDPOS TO LF_DIRLEN.
    SHIFT LF_FULLNAME LEFT BY SY-FDPOS PLACES.
  ENDWHILE.
  LF_FILENAME = PO_FILENAME = LF_FULLNAME.

* Directory bestimmen
  IF LF_DIRLEN > 0.
    PO_DIRECTORY = PI_FULLNAME(LF_DIRLEN).
  ENDIF.

* Extension bestimmen
  WHILE LF_FILENAME CS'.'.
    ADD 1 TO SY-FDPOS.
    SHIFT LF_FILENAME LEFT BY SY-FDPOS PLACES.
  ENDWHILE.
  IF SY-SUBRC = 0.
    LW_EXTENSION = LF_FILENAME.
  ENDIF.
* Copied from DSVAS_DOC_FILENAME_SPLIT --- END

ENDFORM.                    " SPLIT_FILE_AND_PATH
*&---------------------------------------------------------------------*
*&      ユーザーコマンド処理
*&---------------------------------------------------------------------*
*      -->PI_UCOMM  ユーザーコマンド
*----------------------------------------------------------------------*
FORM USER_COMMAND USING PI_UCOMM LIKE SY-UCOMM.

  CASE PI_UCOMM.
    WHEN 'FC01'.                            "Condition Select
*     動的条件の設定
      PERFORM COND_SET USING P_TSTR
                             '範囲選択'
                    CHANGING T_WHERE.
    WHEN 'FC02'.                            "Item Select
*     動的項目選択の設定
      PERFORM SELECT_ITEM USING P_TSTR
                                W_CLNT_FLG
                       CHANGING T_FIELD.
      IF SY-SUBRC = 0.
        IF RB_ARI = C_ON
        AND LINES( T_FIELD-FLD_RANGE ) IS NOT INITIAL.
          CB_FLD = C_ON.
        ENDIF.
      ENDIF.

    WHEN 'FC03'.                            "Count Check
      IF P_TSTR = T_WHERE-TABLENAME.
        SELECT COUNT(*) FROM (P_TSTR) WHERE (T_WHERE-WHERE_TAB[]).
      ELSE.
        SELECT COUNT(*) FROM (P_TSTR).
      ENDIF.

*     SE16の[エントリ数]表示Form
      PERFORM SHOW_COUNT_STAR(SAPLSETB) USING SY-DBCNT.

    WHEN 'FC05'.                                            "Tr-cd:SE16
      PERFORM CALL_SE16 USING P_TSTR.
      GET PARAMETER ID 'DTB' FIELD P_TSTR.
      MESSAGE S398 "DISPLAY LIKE 'W'
              WITH 'データブラウザで入力された選択条件内容は、'
                   '引き継がれていません' '' ''.

  ENDCASE.

ENDFORM.                    " USER_COMMAND
*&---------------------------------------------------------------------*
*&      Form  INIT
*&---------------------------------------------------------------------*
*       実行時の初期処理
*----------------------------------------------------------------------*
FORM INIT .

  FREE:
    T_DD03L,
    T_EXCEL,
    T_ERR_MSG.

* 区切り文字の設定
  CASE C_ON.
    WHEN RB_CSV.
      W_SPLIT = ','.
    WHEN RB_TAB.
      W_SPLIT = CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB.
    WHEN RB_INP.
      W_SPLIT = P_CHR.
  ENDCASE.

* クライアントチェック
  PERFORM T000_CHK.

ENDFORM.                    " INIT
*&---------------------------------------------------------------------*
*&      クライアントチェック
*&---------------------------------------------------------------------*
FORM T000_CHK.

  SELECT SINGLE *
    FROM T000
   WHERE  MANDT  =  SY-MANDT.

  IF SY-SUBRC =  0.
    CHECK ( RB_ET  = C_ON AND CB_CHK IS INITIAL )
       OR ( RB_DEL = C_ON ).

*   本番機の時は,透過ﾃｰﾌﾞﾙへの更新を確認する
    IF T000-CCCATEGORY = 'P'.
      PERFORM POPUP_TO_CONFIRM USING 'クライアント確認'
                                     '本稼動クライアントです。'
                                     '本当に更新しますか？'
                                     '2' 'W'
                            CHANGING W_ANSWER.

      IF W_ANSWER <> '1'.
        MESSAGE S398 DISPLAY LIKE 'E'
                WITH '処理を中止しました' '' '' ''.
        STOP.
      ENDIF.
    ENDIF.

  ELSE.
    MESSAGE E163 DISPLAY LIKE 'E' WITH SY-MANDT.
*   クライアント & は使用できません 既存のクライアントを選択してください
    STOP.
  ENDIF.

ENDFORM.                                                    " T000_CHK
*&---------------------------------------------------------------------*
*&     対象テーブルの構造、属性等のチェック
*&---------------------------------------------------------------------*
*      -->PI_STRUCT  テーブル名
*----------------------------------------------------------------------*
FORM STRUCT_CHK USING PI_STRUCT TYPE TABNAME.

  DATA: LW_TITLE    TYPE STRING.

  SELECT  SINGLE *  FROM  DD02L  WHERE  TABNAME  =  PI_STRUCT "#EC *
                                 AND    AS4LOCAL = 'A'.

  IF  SY-SUBRC  =  0.
    W_CLNT_FLG = DD02L-CLIDEP.
    IF  DD02L-TABCLASS  <> 'TRANSP'.             "透過ﾃｰﾌﾞﾙ
      MESSAGE S398 DISPLAY LIKE 'E'
              WITH PI_STRUCT 'は、透過テーブルではありません' '' ''.
      STOP.
    ENDIF.
*
    IF ( RB_ET  = C_ON AND CB_CHK IS INITIAL )
    OR ( RB_DEL = C_ON ).
      CASE C_ON.
        WHEN RB_ET.
          LW_TITLE = 'アップロード確認'.
        WHEN RB_DEL.
          LW_TITLE = '削除確認'.
      ENDCASE.

      IF W_CLNT_FLG IS INITIAL.
        PERFORM POPUP_TO_CONFIRM USING LW_TITLE
                'このテーブルはクライアント非依存です'
                '処理を続行しますか？'
                '2' 'W'
                CHANGING W_ANSWER.
        IF  W_ANSWER  <>  '1'.
          MESSAGE S398 WITH '処理を中止しました' '' '' ''. STOP.
        ENDIF.
      ENDIF.
*
      CASE DD02L-CONTFLAG.
        WHEN 'A'.
        WHEN 'C' OR 'G'.
          PERFORM POPUP_TO_CONFIRM USING LW_TITLE
                  'カスタマイジングテーブルです'
                  '処理を続行しますか？'
                  '2' 'W'
                  CHANGING W_ANSWER.
          IF  W_ANSWER  <>  '1'.
            MESSAGE S398 WITH '処理を中止しました' '' '' ''. STOP.
          ENDIF.
        WHEN OTHERS.
          MESSAGE S398 WITH PI_STRUCT 'は変更できません' '' ''. STOP.
      ENDCASE.
    ENDIF.
  ELSE.
    MESSAGE S398 DISPLAY LIKE 'E'
            WITH 'テーブル名' PI_STRUCT 'は、登録されていません' ''.
    STOP.
  ENDIF.

* テーブル情報取得
  PERFORM GET_DD_INFO TABLES T_DD03L
                       USING PI_STRUCT
                             SPACE.

* テーブル構造の割当
  TRY.
      CREATE DATA REF_ITAB TYPE STANDARD TABLE OF (PI_STRUCT).
      ASSIGN REF_ITAB->* TO <TAB_DATA>.
      CREATE DATA REF_LINE LIKE LINE OF <TAB_DATA>.
      ASSIGN REF_LINE->* TO <TAB_LINE>.

    CATCH CX_SY_CREATE_ERROR .
      MESSAGE S398 DISPLAY LIKE 'E'
              WITH PI_STRUCT 'の内部生成に失敗しました' '' ''.
      STOP.
  ENDTRY.

ENDFORM.                    " STRUCT_CHK
*&---------------------------------------------------------------------*
*&      列見出し作成
*&---------------------------------------------------------------------*
FORM HEAD_CREATE.

  DATA: LW_FLDTXT TYPE STRING,
        LW_FLDNAM TYPE STRING.

  CLEAR: T_EXCEL, W_LENGTH, W_TABIX.

**-- 列見出し作成
  LOOP  AT  T_DD03L.
    CHECK W_CLNT_FLG IS INITIAL
       OR SY-TABIX > 1
       OR T_DD03L-DATATYPE <> 'CLNT'.

    CHECK T_DD03L-FIELDNAME IN T_FIELD-FLD_RANGE.

    ADD 1 TO W_TABIX.

    COMPUTE  W_LENGTH  =  W_LENGTH  +  T_DD03L-INTLEN.

    IF  W_TABIX  =  1.
      IF T_DD03L-COMPTYPE IS INITIAL.
        MOVE  T_DD03L-FIELDTEXT  TO  LW_FLDTXT.
      ELSE.
        MOVE  T_DD03L-SCRTEXT_M  TO  LW_FLDTXT.
      ENDIF.
      MOVE  T_DD03L-FIELDNAME  TO  LW_FLDNAM.
    ELSE.
      IF T_DD03L-COMPTYPE IS INITIAL.
        CONCATENATE LW_FLDTXT     T_DD03L-FIELDTEXT
               INTO LW_FLDTXT     SEPARATED BY W_SPLIT.
      ELSE.
        CONCATENATE LW_FLDTXT     T_DD03L-SCRTEXT_M
               INTO LW_FLDTXT     SEPARATED BY W_SPLIT.
      ENDIF.
      CONCATENATE LW_FLDNAM     T_DD03L-FIELDNAME
             INTO LW_FLDNAM     SEPARATED BY W_SPLIT.
    ENDIF.
  ENDLOOP.

**-- 列見出し作成
  IF RB_ARI  =  C_ON.
    APPEND   LW_FLDTXT TO T_EXCEL.
    IF CB_FLD  =  C_ON.
      APPEND   LW_FLDNAM TO T_EXCEL.
    ENDIF.
  ENDIF.

ENDFORM.                    " HEAD_CREATE
*&---------------------------------------------------------------------*
*&      ダウンロードデータ作成
*&---------------------------------------------------------------------*
FORM EXCEL_CREATE.

  DATA: LT_COND   LIKE TABLE OF WHERE_TAB,
        LW_DREF   TYPE REF TO DATA,
        LW_MAXCNT TYPE I,
        LW_CNT    TYPE I,
        LW_SELFLG TYPE XFELD.
  DATA: CUR1        TYPE CURSOR.

  FIELD-SYMBOLS: <WORK>.
  LW_CNT = LINES( T_EXCEL ).                "ヘッダー行数

** ﾃｰﾌﾞﾙ抽出
  FREE: LT_COND.
  IF T_WHERE-TABLENAME = P_TSTR
  AND LINES( T_WHERE-WHERE_TAB ) IS NOT INITIAL.
*   動的条件を設定する
    LT_COND[] = T_WHERE-WHERE_TAB[].
  ENDIF.
*  PERFORM  TABLE_SELECT_BK USING  P_TSTR.        "ﾃｰﾌﾞﾙ抽出

  SELECT COUNT(*) FROM (P_TSTR) INTO LW_MAXCNT WHERE (LT_COND).
  CHECK LW_MAXCNT > 0.

  IF P_ROWS IS INITIAL.
    IF LW_MAXCNT > 65535.
      PERFORM POPUP_TO_CONFIRM USING '抽出確認'
              'EXCELでの最大表示可能件数を超えています'
              '全レコードを抽出しますか？'
              '2' 'Q'
              CHANGING W_ANSWER.
      IF  W_ANSWER  <>  '1'.
        MESSAGE S398 WITH 'ダウンロードを中止しました' '' '' ''. STOP.
      ENDIF.
    ELSEIF LINES( LT_COND ) IS INITIAL.
      PERFORM POPUP_TO_CONFIRM USING '抽出確認'
              '全レコードを抽出します'
              'よろしいですか？'
              '2' 'Q'
              CHANGING W_ANSWER.
      IF  W_ANSWER  <>  '1'.
        MESSAGE S398 WITH 'ダウンロードを中止しました' '' '' ''. STOP.
      ENDIF.
    ENDIF.
  ENDIF.

  PERFORM DISPLAY_INDICATOR USING LW_MAXCNT 0
          'データ作成中。しばらくお待ち下さい...' ''.
  OPEN CURSOR CUR1 FOR
    SELECT  *  FROM (P_TSTR)
              WHERE (LT_COND)
              ORDER BY PRIMARY KEY.

  DO.
    FETCH NEXT CURSOR CUR1 INTO <TAB_LINE>.
    IF SY-SUBRC <> 0.
      W_OVER = C_OFF.
      EXIT.
    ENDIF.

    IF P_ROWS = 0.
    ELSEIF SY-DBCNT > P_ROWS.
      W_OVER = C_ON.
      EXIT.
    ENDIF.

    CLEAR: T_EXCEL, W_TABIX.

    DO.
      ASSIGN COMPONENT SY-INDEX OF STRUCTURE <TAB_LINE>
             TO <TAB_ITEM>.
      IF SY-SUBRC <> 0. EXIT. ENDIF.

      READ TABLE T_DD03L INDEX SY-INDEX.
      IF SY-INDEX = 1 AND W_CLNT_FLG = C_ON.
        CHECK T_DD03L-DATATYPE <> 'CLNT'.
      ENDIF.
*
      CHECK T_DD03L-FIELDNAME IN T_FIELD-FLD_RANGE.
*
      CREATE DATA LW_DREF TYPE C LENGTH T_DD03L-OUTPUTLEN.
      ASSIGN LW_DREF->* TO <WORK>.


* FORMAT変換(OUTPUT)
      PERFORM CONV_DATA_OUT TABLES  T_DD03L
                             USING  <TAB_LINE>
                                    <TAB_ITEM>
                          CHANGING  <WORK>.

      IF  W_TABIX  =  0.
        MOVE  <WORK>  TO  T_EXCEL.
      ELSE.
        CONCATENATE T_EXCEL <WORK> INTO T_EXCEL
                    SEPARATED BY W_SPLIT.
      ENDIF.
      ADD 1 TO W_TABIX.
    ENDDO.
    APPEND  T_EXCEL.
    ADD 1 TO LW_CNT.
  ENDDO.

  CLOSE CURSOR CUR1.

  FREE: <TAB_DATA>.

  PERFORM DISPLAY_INDICATOR USING LW_MAXCNT LW_MAXCNT
          'データ作成完了' ''.

ENDFORM.                    "
*&---------------------------------------------------------------------*
*&      ファイルダウンロード
*&---------------------------------------------------------------------*
FORM EXCEL_DOWNLOAD.

  DATA: LW_FILENAM TYPE STRING,
        LW_FILETYP TYPE CHAR10.

**--  ﾀﾞｳﾝﾛｰﾄﾞ確認Popup出力
  PERFORM  POPUP_DL_CHK.

  MESSAGE S398 WITH 'ダウンロード中。しばらくお待ち下さい...' '' '' ''.

  LW_FILENAM = W_FPATH.
  LW_FILETYP = P_TYP.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      FILENAME                = LW_FILENAM
      FILETYPE                = LW_FILETYP
      APPEND                  = ' '
      WRITE_FIELD_SEPARATOR   = ' '
      CONFIRM_OVERWRITE       = 'X'
    TABLES
      DATA_TAB                = T_EXCEL
    EXCEPTIONS
      FILE_WRITE_ERROR        = 1
      NO_BATCH                = 2
      GUI_REFUSE_FILETRANSFER = 3
      INVALID_TYPE            = 4
      NO_AUTHORITY            = 5
      UNKNOWN_ERROR           = 6
      HEADER_NOT_ALLOWED      = 7
      SEPARATOR_NOT_ALLOWED   = 8
      FILESIZE_NOT_ALLOWED    = 9
      HEADER_TOO_LONG         = 10
      DP_ERROR_CREATE         = 11
      DP_ERROR_SEND           = 12
      DP_ERROR_WRITE          = 13
      UNKNOWN_DP_ERROR        = 14
      ACCESS_DENIED           = 15
      DP_OUT_OF_MEMORY        = 16
      DISK_FULL               = 17
      DP_TIMEOUT              = 18
      FILE_NOT_FOUND          = 19
      DATAPROVIDER_EXCEPTION  = 20
      CONTROL_FLUSH_ERROR     = 21
      OTHERS                  = 22.

  IF SY-SUBRC =  0.
    IF W_OVER IS INITIAL.
      MESSAGE S398 WITH 'ﾀﾞｳﾝﾛｰﾄﾞ件数 =' W_DATA_CNT '件' ''.
    ELSE.
      MESSAGE S398 WITH 'すべての該当対象の中から' W_DATA_CNT
                        '件だけがﾀﾞｳﾝﾛｰﾄﾞされました' ''.
    ENDIF.
  ELSE.
    MESSAGE S398 WITH 'GUI_DOWNLOAD ERROR / RC =' SY-SUBRC '/' W_FPATH.
    STOP.
  ENDIF.

  FREE: T_EXCEL.

ENDFORM.                    " EXCEL_DOWNLOAD
*&---------------------------------------------------------------------*
*&      ﾀﾞｳﾝﾛｰﾄﾞ確認Popup出力
*&---------------------------------------------------------------------*
FORM POPUP_DL_CHK.

  DESCRIBE  TABLE  T_EXCEL  LINES  W_DATA_CNT.

  IF  RB_ARI  =  C_ON.
    IF CB_FLD = C_OFF.
      W_DATA_CNT  =  W_DATA_CNT  -  1.
    ELSE.
      W_DATA_CNT  =  W_DATA_CNT  -  2.
    ENDIF.
  ENDIF.

  CHECK  W_DATA_CNT  <  1.

  IF  RB_ARI  =  C_ON.
    PERFORM POPUP_TO_CONFIRM USING 'ダウンロード確認'
                                   '対象データがありません'
                                   '列見出しのみダウンロードしますか'
                                   '1' 'Q'
                          CHANGING W_ANSWER.
    IF  W_ANSWER  <>  '1'.
      MESSAGE S398 WITH 'ダウンロードを中止しました' '' '' ''. STOP.
    ENDIF.
  ELSE.
    MESSAGE S398 WITH '対象データがありません' '' '' ''. STOP.
  ENDIF.

ENDFORM.                    " POPUP
*&---------------------------------------------------------------------*
*&      ファイルアップロード
*&---------------------------------------------------------------------*
FORM EXCEL_UPLOAD.

  DATA: LW_FILENAM TYPE STRING,
        LW_FILETYP TYPE CHAR10.

  MESSAGE S398 WITH 'アップロード中。しばらくお待ち下さい...' '' '' ''.

  LW_FILENAM = W_FPATH.
  LW_FILETYP = P_TYP.

  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      FILENAME                = LW_FILENAM
      FILETYPE                = LW_FILETYP
      HAS_FIELD_SEPARATOR     = ' '
    TABLES
      DATA_TAB                = T_EXCEL
    EXCEPTIONS
      FILE_OPEN_ERROR         = 1
      FILE_READ_ERROR         = 2
      NO_BATCH                = 3
      GUI_REFUSE_FILETRANSFER = 4
      INVALID_TYPE            = 5
      NO_AUTHORITY            = 6
      UNKNOWN_ERROR           = 7
      BAD_DATA_FORMAT         = 8
      HEADER_NOT_ALLOWED      = 9
      SEPARATOR_NOT_ALLOWED   = 10
      HEADER_TOO_LONG         = 11
      UNKNOWN_DP_ERROR        = 12
      ACCESS_DENIED           = 13
      DP_OUT_OF_MEMORY        = 14
      DISK_FULL               = 15
      DP_TIMEOUT              = 16
      OTHERS                  = 17.

  IF SY-SUBRC <> 0.
    MESSAGE S398 WITH 'GUI_UPLOAD ERROR / RC =' SY-SUBRC '/' W_FPATH.
    STOP.
  ENDIF.

  IF LINES( T_EXCEL[] ) = 0.
    MESSAGE S398 WITH '対象データがありません' '' '' ''. STOP.
  ENDIF.

ENDFORM.                    " EXCEL_UPLOAD
*&---------------------------------------------------------------------*
*&      テーブル更新
*&---------------------------------------------------------------------*
FORM TABLE_UPDATE.

*  DATA: LT_WHERE_DUMMY LIKE TABLE OF WHERE_TAB.
  DATA: LW_MSG LIKE SY-MSGV1,
        LW_RC  LIKE SY-SUBRC.

  DESCRIBE TABLE <TAB_DATA> LINES W_DATA_CNT.
  IF  W_DATA_CNT  =  0.
    MESSAGE S398 WITH '対象データがありません' '' '' ''. STOP.
  ENDIF.

  IF CB_CHK = C_ON.
    IF T_ERR_MSG[] IS INITIAL.
      MESSAGE S398 WITH 'エラーデータなし(アップロード対象件数:'
                         W_DATA_CNT '件)' ''.
    ELSE.
      PERFORM  UPLOAD_LOG.                            "
      MESSAGE S398 WITH 'エラー内容を確認して下さい' '' '' ''.
    ENDIF.
    STOP.
  ENDIF.

  MESSAGE S398 WITH '更新処理を開始します' '' '' ''.

**--  ｱｯﾌﾟﾛｰﾄﾞ確認Popup出力
  IF T_ERR_MSG[] IS INITIAL.
    MESSAGE S398 WITH W_DATA_CNT '件' '' '' INTO LW_MSG.
    PERFORM POPUP_TO_CONFIRM USING 'ＤＢ更新確認'
                                   'テーブルを更新しますか？'
                                   LW_MSG
                                   '2' 'Q'
                          CHANGING W_ANSWER.
  ELSE.
    PERFORM POPUP_TO_CONFIRM USING 'ＤＢ更新確認'
                                   '変換エラーデータがありました。'
                                   'テーブル更新を続行しますか？'
                                   '2' 'W'
                          CHANGING W_ANSWER.
  ENDIF.
  IF  W_ANSWER  <>  '1'.
    PERFORM  UPLOAD_LOG.                            "
    MESSAGE S398 WITH 'アップロードを中止しました' '' '' ''. STOP.
  ENDIF.

* テーブル更新
  PERFORM TABLE_MODIFY TABLES <TAB_DATA>
                        USING 'M' P_TSTR
                     CHANGING LW_RC.
  IF LW_RC <> 0.
    PERFORM  UPLOAD_LOG.                            "
    STOP.
  ENDIF.

  FREE: <TAB_DATA>.

  CHECK CB_CHK IS INITIAL.
* SE16起動(更新結果確認用)
  PERFORM POPUP_TO_CONFIRM USING '更新確認'
                                 'データブラウザを使用して'
                                 '更新結果を確認しますか？'
                                 '1' 'Q'
                        CHANGING W_ANSWER.
  CHECK W_ANSWER = '1'.

  PERFORM  CALL_SE16 USING P_TSTR.

ENDFORM.                    " TABLE_UPDATE
*&---------------------------------------------------------------------*
*&      テーブル更新
*&---------------------------------------------------------------------*
FORM TABLE_MODIFY TABLES PT_DATA  TYPE TABLE
                   USING PI_PRCMD TYPE C
                         PI_TABNM LIKE RSEDD0-DDOBJNAME
                CHANGING PO_RC    LIKE SY-SUBRC.

  DATA: LW_TAB_CNT TYPE I,
        LW_CNT     TYPE I,
        LW_FR      TYPE SY-INDEX,
        LW_TO      TYPE SY-INDEX,
        LW_REF_TAB TYPE REF TO DATA,
        LW_MODE_NM TYPE SY-MSGV1,
        LW_MSG1    TYPE SY-MSGV1,
        LW_MSG2    TYPE SY-MSGV2,
        LW_CNT2    TYPE I,
        LST_FIT00004 TYPE TY_FIT00004.

  FIELD-SYMBOLS: <LT_DATA> TYPE STANDARD TABLE.

  LW_TAB_CNT = LINES( PT_DATA ).
  LW_CNT = LW_TAB_CNT DIV P_COMMIT + 1.

  CASE PI_PRCMD.
    WHEN 'I'.  LW_MODE_NM = 'ﾃｰﾌﾞﾙ登録'.
    WHEN 'M'.  LW_MODE_NM = 'ﾃｰﾌﾞﾙ更新'.
    WHEN 'D'.  LW_MODE_NM = 'ﾃｰﾌﾞﾙ削除'.
  ENDCASE.

  PERFORM DISPLAY_INDICATOR USING LW_CNT 0
          LW_MODE_NM '中。しばらくお待ち下さい...'.

  IF PI_PRCMD = 'M'.
    LST_FIT00004-MANDT      = SY-MANDT.        "クライアント
    LST_FIT00004-UPDATE_TBL = PI_TABNM.        "テーブル名
    LST_FIT00004-UPDATE_DT  = SY-DATUM.        "更新日付
    LST_FIT00004-UPDATE_TM  = SY-UZEIT.        "更新時刻
    LST_FIT00004-USERID     = SY-UNAME.        "ユーザーID
    LST_FIT00004-ACTION     = 'MODIFY'.        "アクション
    LST_FIT00004-ANPRG      = SY-CPROG.        "登録プログラム
    LST_FIT00004-ANDAT      = SY-DATUM.        "登録日
    LST_FIT00004-ANUZT      = SY-UZEIT.        "登録時刻
    LST_FIT00004-ANNAM      = SY-UNAME.        "登録ユーザ
    LST_FIT00004-AEPRG      = SY-CPROG.        "最終更新プログラム
    LST_FIT00004-AEDAT      = SY-DATUM.        "最終更新日
    LST_FIT00004-AEZET      = SY-UZEIT.        "最終更新時刻
    LST_FIT00004-AENAM      = SY-UNAME.        "最終更新ユーザ
  ENDIF.

  IF LW_TAB_CNT <= P_COMMIT.
    LW_FR = 1.
    LW_TO = LW_TAB_CNT.

    CASE PI_PRCMD.
      WHEN 'I'.
        INSERT  (PI_TABNM)  FROM  TABLE  PT_DATA.
*       リターンコード判定
        IF SY-SUBRC = 0.
          COMMIT WORK.
        ENDIF.
      WHEN 'M'.
        MODIFY  (PI_TABNM)  FROM  TABLE  PT_DATA.
*       リターンコード判定
        IF SY-SUBRC = 0.
*         テーブル一括UL ログテーブル（/SH3/FIT00004）の更新
          PERFORM MODIFY_FIT00004
            USING    'I'
                     LW_TO
                     PI_TABNM
            CHANGING LST_FIT00004.
        ENDIF.
      WHEN 'D'.
        DELETE  (PI_TABNM)  FROM  TABLE  PT_DATA.
*       リターンコード判定
        IF SY-SUBRC = 0.
          COMMIT WORK.
        ENDIF.
    ENDCASE.

  ELSE.
*   TEMP テーブル構造の割当
    CREATE DATA LW_REF_TAB TYPE STANDARD TABLE OF (PI_TABNM).
    ASSIGN LW_REF_TAB->* TO <LT_DATA>.

    LW_FR = 1.
    LW_TO = P_COMMIT.

    DO.
      FREE: <LT_DATA>.
      APPEND LINES OF PT_DATA FROM LW_FR TO LW_TO TO <LT_DATA>.

      CASE PI_PRCMD.
        WHEN 'I'.
          INSERT  (PI_TABNM)  FROM  TABLE  <LT_DATA>.
*         リターンコード判定
          IF SY-SUBRC = 0.
            COMMIT WORK.
          ELSE.
            EXIT.
          ENDIF.
        WHEN 'M'.
          MODIFY  (PI_TABNM)  FROM  TABLE  <LT_DATA>.
*         リターンコード判定
          IF SY-SUBRC = 0.
*           １処理の場合
            IF SY-INDEX = 1.

*             テーブル一括UL ログテーブル（/SH3/FIT00004）の更新
              PERFORM MODIFY_FIT00004
                USING    'I'
                         LW_TO
                         PI_TABNM
                CHANGING LST_FIT00004.

*           ２回目以降の場合
            ELSE.

              LW_CNT2 = LINES( <LT_DATA> ).
              LW_CNT2 = LW_CNT2 + ( SY-INDEX - 1 ) * P_COMMIT.
*             テーブル一括UL ログテーブル（/SH3/FIT00004）の更新
              PERFORM MODIFY_FIT00004
                USING    'U'
                         LW_CNT2
                         PI_TABNM
                CHANGING LST_FIT00004.

            ENDIF.
          ELSE.
            EXIT.
          ENDIF.
        WHEN 'D'.
          DELETE  (PI_TABNM)  FROM  TABLE  <LT_DATA>.
*         リターンコード判定
          IF SY-SUBRC = 0.
            COMMIT WORK.
          ELSE.
            EXIT.
          ENDIF.
      ENDCASE.

      IF SY-SUBRC = 0
      AND LW_TO < LW_TAB_CNT.
        ADD P_COMMIT TO: LW_FR,  LW_TO.
        IF LW_TO > LW_TAB_CNT.
          LW_TO = LW_TAB_CNT.
        ENDIF.
      ELSE.
        EXIT.
      ENDIF.
    ENDDO.
  ENDIF.

  IF SY-SUBRC = 0.
    MESSAGE S398 WITH LW_MODE_NM '件数 = ' LW_TAB_CNT  '件'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE S398 WITH 'ERROR(RC:' SY-SUBRC ')' '' INTO LW_MSG1.
    IF PI_PRCMD = 'D'.
    ELSE.
      IF RB_ARI = C_ON.
        IF CB_FLD = C_OFF.
          ADD 1 TO: LW_FR, LW_TO.
        ELSE.
          ADD 2 TO: LW_FR, LW_TO.
        ENDIF.
      ENDIF.
      MESSAGE S398 WITH '行番号:' LW_FR '～' LW_TO INTO LW_MSG2.
      CONCATENATE '/(' LW_MSG2  ')' INTO LW_MSG2.
    ENDIF.
    MESSAGE S398 WITH LW_MODE_NM LW_MSG1 LW_MSG2 ''.
  ENDIF.

ENDFORM.                    " TABLE_MODIFY
*&---------------------------------------------------------------------*
*&      更新データ作成
*&---------------------------------------------------------------------*
FORM UPF_CREATE.

  DATA: LW_FROM   LIKE SY-TABIX,
        LW_MAXCNT TYPE I,
        LW_SEQ    TYPE I,
        LW_CNT    TYPE I,
        LT_FLDNAM TYPE TABLE OF FIELDNAME.

  FIELD-SYMBOLS: <FS_EXCEL> TYPE STRING,
                 <FS_FLDNM> TYPE FIELDNAME.

**-- 列見出しのチェック
  IF  RB_ARI = C_ON.
    IF  CB_FLD = C_OFF.
      LW_FROM = 2.
      READ TABLE T_EXCEL INDEX LW_FROM TRANSPORTING NO FIELDS.
      IF SY-SUBRC <> 0.
        MESSAGE S398 WITH '対象データがありません' '' '' ''. STOP.
      ENDIF.
      PERFORM CHECK_LAYOUT.
    ELSE.
      LW_FROM = 3.
      READ TABLE T_EXCEL INDEX LW_FROM TRANSPORTING NO FIELDS.
      IF SY-SUBRC <> 0.
        MESSAGE S398 WITH '対象データがありません' '' '' ''. STOP.
      ENDIF.
      READ TABLE T_EXCEL ASSIGNING <FS_EXCEL> INDEX 2.
      SPLIT <FS_EXCEL> AT W_SPLIT INTO TABLE LT_FLDNAM.

      LOOP AT LT_FLDNAM ASSIGNING <FS_FLDNM>.
        READ TABLE T_DD03L WITH KEY FIELDNAME = <FS_FLDNM>
                   TRANSPORTING NO FIELDS.
        IF SY-SUBRC <> 0.
          PERFORM SET_ERR_MSG USING 2 P_TSTR <FS_FLDNM> 5.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSE.
    LW_FROM = 1.
    PERFORM CHECK_LAYOUT.
  ENDIF.

  LW_MAXCNT = LINES( T_EXCEL ).
  PERFORM DISPLAY_INDICATOR USING LW_MAXCNT LW_FROM
          'データ作成中。しばらくお待ち下さい...' ''.

* 登録データの編集
  LOOP  AT  T_EXCEL ASSIGNING <FS_EXCEL> FROM LW_FROM.

    LW_SEQ = SY-TABIX.
    CLEAR: <TAB_LINE>, T_ITEM[].
*   項目値への分割
    SPLIT <FS_EXCEL> AT W_SPLIT INTO TABLE T_ITEM.
*
    CLEAR: LW_CNT.
    LOOP AT T_DD03L.
      ASSIGN COMPONENT T_DD03L-FIELDNAME
              OF STRUCTURE <TAB_LINE> TO <TAB_ITEM>.
      CHECK SY-SUBRC = 0.

      IF W_CLNT_FLG = C_ON
      AND T_DD03L-DATATYPE = 'CLNT'
      AND SY-TABIX = 1.
        <TAB_ITEM> = SY-MANDT.
      ELSE.
        CHECK T_DD03L-FIELDNAME IN T_FIELD-FLD_RANGE.
        IF LT_FLDNAM[] IS INITIAL.
          LW_CNT = LW_CNT + 1.
        ELSE.
          READ TABLE LT_FLDNAM FROM T_DD03L-FIELDNAME
                     TRANSPORTING NO FIELDS.
          CHECK SY-SUBRC = 0.
          LW_CNT = SY-TABIX.
        ENDIF.

        READ TABLE T_ITEM INTO H_ITEM INDEX LW_CNT.

        CHECK SY-SUBRC = 0.
        PERFORM CONV_DATA_IN TABLES T_ITEM
                                    T_DD03L
                              USING LW_SEQ
                                    H_ITEM
                           CHANGING <TAB_ITEM>.
      ENDIF.
    ENDLOOP.

    APPEND <TAB_LINE> TO <TAB_DATA>.

    PERFORM DISPLAY_INDICATOR USING LW_MAXCNT LW_SEQ
            'データ作成中。しばらくお待ち下さい...' ''.
  ENDLOOP.

  FREE: T_EXCEL.

  PERFORM DISPLAY_INDICATOR USING LW_MAXCNT LW_MAXCNT
          'データ作成完了' ''.

ENDFORM.                    " UPF_CREATE
*&---------------------------------------------------------------------*
*&      動的条件の設定
*&---------------------------------------------------------------------*
*      -->PI_STRUCT  テーブル名
*      -->PI_TITLE   選択画面表題
*      <--PO_WHERE   動的条件
*&---------------------------------------------------------------------*
FORM COND_SET USING PI_STRUCT TYPE TABNAME
                    PI_TITLE  TYPE C
           CHANGING PO_WHERE  TYPE RSDS_WHERE.

  DATA: LT_FLDS  TYPE TABLE OF RSDSFIELDS,
        LT_EXPR  TYPE RSDS_TEXPR,
        LT_WHERE TYPE RSDS_TWHERE.

  DATA: "LA_WHERE    LIKE LINE  OF LT_WHERE,
        LW_SELID    LIKE RSDYNSEL-SELID.

  MESSAGE S398 WITH '選択範囲を入力後、'
                    '実行ボタン(F8)を押下して下さい' '' ''.

* 動的選択:初期設定
  PERFORM CALL_SELECT_INIT TABLES LT_FLDS
                            USING 'T'
                                  PI_STRUCT
                         CHANGING LW_SELID
                                  LT_EXPR.

  CALL FUNCTION 'FREE_SELECTIONS_DIALOG'
    EXPORTING
      SELECTION_ID    = LW_SELID
      TITLE           = PI_TITLE
      FRAME_TEXT      = '抽出条件'
      STATUS          = 1
      AS_WINDOW       = ' '
      DIAG_TEXT_2     = '全てのレコードが'
                        &
                        '対象になります'
    IMPORTING
      WHERE_CLAUSES   = LT_WHERE
      EXPRESSIONS     = LT_EXPR
    TABLES
      FIELDS_TAB      = LT_FLDS
    EXCEPTIONS
      INTERNAL_ERROR  = 1
      NO_ACTION       = 2
      SELID_NOT_FOUND = 3
      ILLEGAL_STATUS  = 4
      OTHERS          = 5.

  CASE SY-SUBRC.
    WHEN 0.
*     Save to ABAP Memory
      EXPORT FLDS_TAB = LT_FLDS
             EXPR_TAB = LT_EXPR TO MEMORY ID 'COND_TEXPR'.

      FREE: PO_WHERE.
      IF LT_WHERE[] IS NOT INITIAL.
        READ TABLE LT_WHERE INTO PO_WHERE
                            WITH KEY TABLENAME = PI_STRUCT.
      ENDIF.
    WHEN 2.
*     Save to ABAP Memory
      EXPORT FLDS_TAB = LT_FLDS
             EXPR_TAB = LT_EXPR TO MEMORY ID 'COND_TEXPR'.

      MESSAGE S398 DISPLAY LIKE 'E'
              WITH '処理を中止しました' '' '' ''.
    WHEN OTHERS.
      MESSAGE S398 DISPLAY LIKE 'E'
              WITH '動的選択 ERROR SY-SUBRC =' SY-SUBRC '' ''.
  ENDCASE.

ENDFORM.                    " COND_SET
*&---------------------------------------------------------------------*
*&      Form  CALL_SELECT_INIT
*&---------------------------------------------------------------------*
*       動的選択:初期設定
*----------------------------------------------------------------------*
*      -->PI_KIND   項目一覧タイプ
*      -->PI_TABS   テーブル名
*      <--PO_SELID  動的選択:画面ID
*      <--PO_EXPR   初期選択値
*      <--PT_FLDS   事前選択項目
*----------------------------------------------------------------------*
FORM CALL_SELECT_INIT TABLES PT_FLDS  STRUCTURE RSDSFIELDS
                       USING PI_KIND  TYPE SYCHAR01
                             PI_TABS  TYPE TABNAME
                    CHANGING PO_SELID TYPE RSDYNSEL-SELID
                             PO_EXPR  TYPE RSDS_TEXPR.

  DATA: LT_TABS    TYPE TABLE OF RSDSTABS,
        LT_OLD_SEL TYPE RSDS_TEXPR,
        LA_TABS    LIKE LINE  OF LT_TABS.

  LA_TABS-PRIM_TAB = PI_TABS.
  APPEND LA_TABS TO LT_TABS.

  IMPORT FLDS_TAB = PT_FLDS
         EXPR_TAB = LT_OLD_SEL FROM MEMORY ID 'COND_TEXPR'.
  IF SY-SUBRC = 0.
    FREE MEMORY ID 'COND_TEXPR'.
    DELETE PT_FLDS    WHERE TABLENAME <> PI_TABS.
    DELETE LT_OLD_SEL WHERE TABLENAME <> PI_TABS.
  ENDIF.

  CALL FUNCTION 'FREE_SELECTIONS_INIT'
    EXPORTING
      KIND                     = PI_KIND
      EXPRESSIONS              = LT_OLD_SEL
    IMPORTING
      SELECTION_ID             = PO_SELID
      EXPRESSIONS              = PO_EXPR
    TABLES
      TABLES_TAB               = LT_TABS
      FIELDS_TAB               = PT_FLDS
    EXCEPTIONS
      FIELDS_INCOMPLETE        = 1
      FIELDS_NO_JOIN           = 2
      FIELD_NOT_FOUND          = 3
      NO_TABLES                = 4
      TABLE_NOT_FOUND          = 5
      EXPRESSION_NOT_SUPPORTED = 6
      INCORRECT_EXPRESSION     = 7
      ILLEGAL_KIND             = 8
      AREA_NOT_FOUND           = 9
      INCONSISTENT_AREA        = 10
      KIND_F_NO_FIELDS_LEFT    = 11
      KIND_F_NO_FIELDS         = 12
      TOO_MANY_FIELDS          = 13
      DUP_FIELD                = 14
      FIELD_NO_TYPE            = 15
      FIELD_ILL_TYPE           = 16
      DUP_EVENT_FIELD          = 17
      NODE_NOT_IN_LDB          = 18
      AREA_NO_FIELD            = 19
      OTHERS                   = 20.

  IF SY-SUBRC <> 0.
    MESSAGE S398 WITH 'SELECT_INIT ERROR SY-SUBRC =' SY-SUBRC '' ''.
    STOP.
  ENDIF.

ENDFORM.                    " CALL_SELECT_INIT
*&---------------------------------------------------------------------*
*&      動的項目選択の設定
*&---------------------------------------------------------------------*
*      -->PI_STRUCT  テーブル名
*----------------------------------------------------------------------*
FORM SELECT_ITEM USING PI_STRUCT TYPE TABNAME
                       PI_CLNT   TYPE XFELD
              CHANGING PO_FIELD  TYPE TYP_FIELD.

  DATA: BEGIN OF LA_DD03P.
          INCLUDE STRUCTURE DD03P.
  DATA: MARK TYPE C,
        END   OF LA_DD03P.

  DATA: LT_DFIES LIKE TABLE OF DFIES,
        LT_DD03P LIKE TABLE OF LA_DD03P.
  DATA: LW_FIRST    TYPE XFELD.
  FIELD-SYMBOLS: <LFS_DFIES> TYPE DFIES.

  IF PO_FIELD-TABNAME <> PI_STRUCT.
    CLEAR: PO_FIELD.
    PO_FIELD-TABNAME = PI_STRUCT.
  ENDIF.

  PERFORM GET_DD_INFO TABLES LT_DFIES
                       USING PI_STRUCT
                             SPACE.

  LOOP AT LT_DFIES ASSIGNING <LFS_DFIES>.
    CHECK SY-TABIX > 1
       OR PI_CLNT  = C_OFF.

    CLEAR: LA_DD03P.
    MOVE-CORRESPONDING <LFS_DFIES> TO LA_DD03P.
    IF <LFS_DFIES>-COMPTYPE IS INITIAL.
      LA_DD03P-DDTEXT = <LFS_DFIES>-FIELDTEXT.
    ELSE.
      LA_DD03P-DDTEXT = <LFS_DFIES>-SCRTEXT_M.
    ENDIF.
    IF LA_DD03P-FIELDNAME IN PO_FIELD-FLD_RANGE.
      LA_DD03P-MARK = C_ON.
    ENDIF.
    APPEND LA_DD03P TO LT_DD03P.
  ENDLOOP.

  CALL FUNCTION 'DD_LIST_TABFIELDS'
    TABLES
      FIELDTAB     = LT_DD03P
    EXCEPTIONS
      NOT_EXECUTED = 1
      OTHERS       = 2.

  CASE SY-SUBRC.
    WHEN 0.
      LW_FIRST = C_ON.
      LOOP AT LT_DD03P INTO LA_DD03P WHERE MARK = C_ON.
*        AT FIRST.
*          FREE: PO_FIELD-FLD_RANGE.
*        ENDAT.
        IF LW_FIRST = C_ON.
          FREE: PO_FIELD-FLD_RANGE.
          LW_FIRST = C_OFF.
        ENDIF.
        PERFORM SET_RANGES_DATA TABLES PO_FIELD-FLD_RANGE
                USING 'I' 'EQ' LA_DD03P-FIELDNAME SPACE.
      ENDLOOP.
      IF SY-SUBRC = 0.
        IF LINES( PO_FIELD-FLD_RANGE ) = LINES( LT_DD03P ).
          FREE: PO_FIELD-FLD_RANGE.
        ENDIF.
      ELSE.
*       １つも選択されていない場合、直前の設定を復元
        MESSAGE S398 DISPLAY LIKE 'E'
                WITH '対象項目を1つ以上選択して下さい' '' '' ''.
      ENDIF.
    WHEN 1.
      MESSAGE S398 DISPLAY LIKE 'E'
              WITH '項目選択を中止しました' '' '' ''.
    WHEN OTHERS.
      MESSAGE S398 DISPLAY LIKE 'E'
              WITH '項目選択 ERROR SY-SUBRC =' SY-SUBRC '' ''.
  ENDCASE.

ENDFORM.                    " SELECT_ITEM
*&---------------------------------------------------------------------*
*&      FORMAT変換(OUTPUT)
*&---------------------------------------------------------------------*
FORM CONV_DATA_OUT TABLES PI_DD03L   STRUCTURE DFIES
                    USING PI_ITEM    TYPE ANY
                          PI_DATA    TYPE ANY
                 CHANGING PO_DATA    TYPE ANY.

  DATA:
    L_SPLIT(2) TYPE C,
    PI_INTTYPE TYPE INTTYPE.

  CLEAR: PO_DATA.

  PI_INTTYPE = PI_DD03L-INTTYPE.

  CASE PI_INTTYPE.
    WHEN 'P' OR 'I'.
      WRITE PI_DATA TO PO_DATA NO-GAP.

* 金額書式変換
      IF CB_CHAN = C_ON.
* 金額の項目判断
        IF PI_DD03L-DATATYPE = C_CURR.
          PERFORM CONV_DATA_CURR_OUT  TABLES  PI_DD03L
                                       USING  PI_ITEM
                                              PI_DATA
                                    CHANGING  PO_DATA.
        ENDIF.
      ENDIF.

      PERFORM SIGN_IN_FRONT CHANGING PO_DATA.
    WHEN 'F' OR 'X'.
      MOVE PI_DATA TO PO_DATA.
    WHEN 'D' OR 'T'.
      IF NOT PI_DATA IS INITIAL.
        WRITE PI_DATA TO PO_DATA.                           "#EC *
      ENDIF.
    WHEN OTHERS.
      IF CB_EXIT = C_ON.
        WRITE PI_DATA TO PO_DATA.
      ELSE.
        MOVE PI_DATA TO PO_DATA.
      ENDIF.
      CASE W_SPLIT.
        WHEN CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB.
        WHEN SPACE.
*--       区切り文字がスペースの場合は、項目値から空白文字を削除
          CONDENSE   PO_DATA  NO-GAPS.
        WHEN OTHERS.
*--       区切り文字と同じ値は、スペースに置換する
          L_SPLIT+0(1) = W_SPLIT.
          TRANSLATE  PO_DATA  USING  L_SPLIT.
*          CONDENSE   PO_DATA  NO-GAPS.
      ENDCASE.
*
  ENDCASE.

ENDFORM.                    " CONV_DATA_OUT
*&---------------------------------------------------------------------*
*&      FORMAT変換(INPUT)
*&---------------------------------------------------------------------*
*       -->PI_INTTYPE  ABAPデータ型
*       -->PI_SEQ      行番号
*       -->PI_DATA     入力データ
*       <--PO_DATA     出力データ
*----------------------------------------------------------------------*
FORM CONV_DATA_IN TABLES PI_ITEM           "STRING
                         PI_DD03L   STRUCTURE DFIES
                   USING PI_SEQ     TYPE ANY
                         PI_DATA    TYPE CLIKE
                CHANGING PO_DATA    TYPE ANY.
  DATA: LW_DATA TYPE STRING,
        LW_TIME LIKE SY-UZEIT,
        LW_RC   TYPE C.
  DATA: LW_DREF        TYPE REF TO DATA.

  DATA: LW_OUTLEN      TYPE OUTPUTLEN.

  DATA: LW_INT     TYPE I,
        LW_CURR_UP TYPE STRING,
        LW_INT_COM TYPE I,
        LW_INT_NUM TYPE I.

  FIELD-SYMBOLS: <WORK>.

  CLEAR: PO_DATA.

* ドメイン依存の出力領域を作成

  IF PI_DD03L-INTTYPE = 'P' OR
     PI_DD03L-INTTYPE = 'I'.
    CLEAR LW_OUTLEN.
*   ファイルのデータの長さよりワークアリアの長さをセットする
    LW_INT = PI_DD03L-POSITION - 1.
    READ TABLE PI_ITEM INTO LW_CURR_UP INDEX LW_INT.
    LW_INT_NUM = STRLEN( LW_CURR_UP ).
    LW_INT_COM = LW_INT_NUM DIV 3.
    LW_OUTLEN = LW_INT_NUM + LW_INT_COM + 3.
    CREATE DATA LW_DREF TYPE C LENGTH LW_OUTLEN.
  ELSE.
    CREATE DATA LW_DREF TYPE C LENGTH PI_DD03L-OUTPUTLEN.
  ENDIF.

  ASSIGN LW_DREF->* TO <WORK>.

  CASE PI_DD03L-INTTYPE.
    WHEN 'P' OR 'I'.                             "Numeric
      LW_DATA = PI_DATA.
      TRANSLATE LW_DATA USING '" + '.
      CONDENSE LW_DATA NO-GAPS.
      WRITE LW_DATA TO <WORK> RIGHT-JUSTIFIED.
*
      CALL FUNCTION 'CATS_NUMERIC_INPUT_CHECK'
        EXPORTING
          INPUT      = <WORK>
        IMPORTING
          OUTPUT     = <WORK>
        EXCEPTIONS
          NO_NUMERIC = 1
          OTHERS     = 2.

      IF SY-SUBRC = 0.
        PERFORM CONV_DATA_CURR_IN TABLES PI_ITEM
                                         PI_DD03L
                                   USING <WORK>
                                         PI_SEQ
                                         PI_DD03L-SCRTEXT_M
                                         '4'
                                CHANGING PO_DATA.
      ELSE.
        PERFORM SET_ERR_MSG
          USING PI_SEQ PI_DD03L-SCRTEXT_M PI_DATA '1'.
      ENDIF.

    WHEN 'F'.                                    "FLTP
      PERFORM DATA_MOVE USING PI_SEQ
                              PI_DD03L-SCRTEXT_M
                              PI_DATA
                              '6'
                     CHANGING PO_DATA.

    WHEN 'X'.                                    "Hex
      PERFORM DATA_MOVE USING PI_SEQ
                              PI_DD03L-SCRTEXT_M
                              PI_DATA
                              '7'
                     CHANGING PO_DATA.

    WHEN 'D'.                                    "Date
      <WORK> = LW_DATA = PI_DATA.
      TRANSLATE LW_DATA USING '/ '.
      CONDENSE: LW_DATA NO-GAPS,
                <WORK>  NO-GAPS.
      IF LW_DATA IS INITIAL
      OR LW_DATA CO ' 0'
      OR <WORK> = '0000/00/00'
      OR <WORK> IS INITIAL.
      ELSE.
        CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
          EXPORTING
            DATE_EXTERNAL            = <WORK>
          IMPORTING
            DATE_INTERNAL            = PO_DATA
          EXCEPTIONS
            DATE_EXTERNAL_IS_INVALID = 1
            OTHERS                   = 2.
        IF SY-SUBRC <> 0.
          PERFORM SET_ERR_MSG
            USING PI_SEQ PI_DD03L-SCRTEXT_M PI_DATA '2'.
        ENDIF.
      ENDIF.

    WHEN 'T'.                                    "Time
      <WORK> = LW_DATA = PI_DATA.
      TRANSLATE LW_DATA USING ': '.
      CONDENSE: LW_DATA NO-GAPS,
                <WORK>  NO-GAPS.
      IF LW_DATA IS INITIAL
      OR LW_DATA CO ' 0'
      OR <WORK>  IS INITIAL.
      ELSE.
        IF <WORK> NA ':'.
          OVERLAY <WORK> WITH '000000'.
        ENDIF.
        CALL FUNCTION 'CONVERT_TIME_INPUT'
          EXPORTING
            INPUT                     = <WORK>
          IMPORTING
            OUTPUT                    = LW_TIME
          EXCEPTIONS
            PLAUSIBILITY_CHECK_FAILED = 1
            WRONG_FORMAT_IN_INPUT     = 2
            OTHERS                    = 3.
        IF SY-SUBRC = 0.
          PO_DATA = LW_TIME.
        ELSE.
          PERFORM SET_ERR_MSG
            USING PI_SEQ PI_DD03L-SCRTEXT_M PI_DATA '8'.
        ENDIF.
      ENDIF.

    WHEN OTHERS.
      <WORK> = PI_DATA.
*     EXIT 変換
      PERFORM CONV_EXIT USING 'I' PI_DD03L-ROLLNAME PI_DD03L-CONVEXIT
                     CHANGING <WORK>  LW_RC.
      PERFORM SET_ERR_MSG
              USING PI_SEQ PI_DD03L-SCRTEXT_M PI_DATA LW_RC.

      PERFORM DATA_MOVE USING PI_SEQ
                              PI_DD03L-SCRTEXT_M
                              <WORK>
                              '4'
                     CHANGING PO_DATA.
  ENDCASE.

ENDFORM.                    " CONV_DATA_TYPE
*&---------------------------------------------------------------------*
*&      EXIT 変換
*&---------------------------------------------------------------------*
*       -->PI_PRCMD     処理区分(I:Input/O:Output)
*       -->PI_ROLLNAME  項目名
*       -->PI_CONVEXIT  変換ルーチン
*       <->PO_DATA      I/O DATA
*       <--PO_RC        戻り値(0:エラーなし/3:エラーあり)
*----------------------------------------------------------------------*
FORM CONV_EXIT USING PI_PRCMD    TYPE SYCHAR01
                     PI_ROLLNAME TYPE ROLLNAME
                     PI_CONVEXIT TYPE CONVEXIT
            CHANGING PO_DATA     TYPE ANY
                     PO_RC       TYPE ANY.

  DATA: LW_DREF      TYPE REF TO DATA,
        LW_FUNC_NAME TYPE FUNCNAME.
  FIELD-SYMBOLS: <DREF> TYPE ANY.

  CLEAR: PO_RC.
* EXIT変換の有無をチェック
  CHECK PI_CONVEXIT IS NOT INITIAL.
  CHECK CB_EXIT = C_ON.

  IF PI_CONVEXIT = 'ABPSP' OR              "PS-Exit
     PI_CONVEXIT = 'KONPD'.

    CREATE DATA LW_DREF TYPE PRPS-POSID.
  ELSE.
    CREATE DATA LW_DREF TYPE (PI_ROLLNAME).
  ENDIF.

  ASSIGN LW_DREF->* TO <DREF>.

  TRY.

      <DREF> = PO_DATA.

    CATCH CX_SY_CONVERSION_ERROR
          CX_SY_ARITHMETIC_OVERFLOW
          CX_SY_MOVE_CAST_ERROR.

      PO_RC = '3'.
      EXIT.
  ENDTRY.

* 汎用モジュール名の編集
  IF PI_PRCMD = 'I'.
    LW_FUNC_NAME = C_FUNC_CONV_IN.
  ELSE.
    LW_FUNC_NAME = C_FUNC_CONV_OUT.
  ENDIF.
  REPLACE '?' WITH PI_CONVEXIT INTO  LW_FUNC_NAME.

* FUNCTION 存在チェック
  CALL FUNCTION 'FUNCTION_EXISTS'
    EXPORTING
      FUNCNAME           = LW_FUNC_NAME
    EXCEPTIONS
      FUNCTION_NOT_EXIST = 1
      OTHERS             = 2.
  IF SY-SUBRC <> 0.
    PO_RC = '3'.
    EXIT.
  ENDIF.

  TRY.
*   汎用モジュールにてEXIT処理
      CALL FUNCTION LW_FUNC_NAME
        EXPORTING
          INPUT  = <DREF>
        IMPORTING
          OUTPUT = <DREF>
        EXCEPTIONS
          OTHERS = 4.
      IF SY-SUBRC = 0.
        PO_DATA = <DREF>.
      ELSE.
        PO_RC = '3'.
      ENDIF.

    CATCH CX_SY_DYN_CALL_PARAM_MISSING
          CX_SY_DYN_CALL_PARAM_NOT_FOUND
          CX_SY_DYN_CALL_ILLEGAL_TYPE.

      PO_RC = '3'.
      EXIT.
  ENDTRY.

ENDFORM.                    " CONV_EXIT
*&---------------------------------------------------------------------*
*&      マイナス符号の前移動
*&---------------------------------------------------------------------*
FORM SIGN_IN_FRONT CHANGING PI_VALUE TYPE ANY.

  DATA: LW_DUMMY(1) TYPE C.                                 "#EC NEEDED

  SEARCH PI_VALUE FOR '-'.
  IF SY-SUBRC = 0 AND SY-FDPOS <> 0.
    SPLIT PI_VALUE AT '-' INTO PI_VALUE LW_DUMMY.
    CONDENSE PI_VALUE.
    CONCATENATE '-' PI_VALUE INTO PI_VALUE.
  ELSE.
    CONDENSE PI_VALUE.
  ENDIF.

ENDFORM.                    " SIGN_IN_FRONT
*&---------------------------------------------------------------------*
*&      Form  DATA_MOVE
*&---------------------------------------------------------------------*
*       データの割当(TRY命令付き)
*----------------------------------------------------------------------*
*      -->PI_SEQ    行番号
*      -->PI_TEXT   項目名
*      -->PI_DATA   入力データ
*      -->PI_ERRCD  エラーコード
*      <--PO_DATA   出力データ
*----------------------------------------------------------------------*
FORM DATA_MOVE USING PI_SEQ   TYPE ANY
                     PI_TEXT  TYPE CLIKE
                     PI_DATA  TYPE ANY
                     PI_ERRCD TYPE ANY
            CHANGING PO_DATA  TYPE ANY.
  TRY.
      PO_DATA = PI_DATA.

    CATCH CX_SY_CONVERSION_ERROR
          CX_SY_ARITHMETIC_OVERFLOW
          CX_SY_MOVE_CAST_ERROR.
      PERFORM SET_ERR_MSG
        USING PI_SEQ PI_TEXT PI_DATA PI_ERRCD.
  ENDTRY.

ENDFORM.                    " DATA_MOVE
*&---------------------------------------------------------------------*
*&      処理ステップの確認
*&---------------------------------------------------------------------*
*       -->PI_TITLE    タイトル
*       -->PI_TEXT1    メッセージ1
*       -->PI_TEXT2    メッセージ2
*       -->PI_DEFAULT  デフォルトボタン(1:Yes/2:No)
*       -->PI_POP_TYP  ポップアップタイプ(Q/I/W/E/C)
*       <--PO_ANSWER   戻り値(1:Yes/2:No/A:Cansel)
*----------------------------------------------------------------------*
FORM POPUP_TO_CONFIRM USING PI_TITLE   TYPE ANY
                            PI_TEXT1   TYPE ANY
                            PI_TEXT2   TYPE ANY
                            PI_DEFAULT TYPE C
                            PI_POP_TYP TYPE C
                   CHANGING PO_ANSWER  TYPE C.

  DATA: LW_QUESTION(200) TYPE C,
        LW_ICON_NAME     LIKE ICON-NAME.

  CLEAR: PO_ANSWER.

  LW_QUESTION = PI_TEXT1.
  IF NOT PI_TEXT2 IS INITIAL.
    LW_QUESTION+48 = PI_TEXT2.
  ENDIF.

  CASE PI_POP_TYP.
    WHEN 'I'.
      LW_ICON_NAME = 'ICON_MESSAGE_INFORMATION'.
    WHEN 'W'.
      LW_ICON_NAME = 'ICON_MESSAGE_WARNING'.
    WHEN 'E'.
      LW_ICON_NAME = 'ICON_MESSAGE_ERROR'.
    WHEN 'C'.
      LW_ICON_NAME = 'ICON_MESSAGE_CRITICAL'.
    WHEN OTHERS.
      LW_ICON_NAME = 'ICON_MESSAGE_QUESTION'.
  ENDCASE.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR       = PI_TITLE
      TEXT_QUESTION  = LW_QUESTION
      TEXT_BUTTON_1  = 'はい'
      TEXT_BUTTON_2  = 'いいえ'
      DEFAULT_BUTTON = PI_DEFAULT
      POPUP_TYPE     = LW_ICON_NAME
    IMPORTING
      ANSWER         = PO_ANSWER
    EXCEPTIONS
      TEXT_NOT_FOUND = 1
      OTHERS         = 2.

  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE 'E' NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " POPUP_TO_CONFIRM
*&---------------------------------------------------------------------*
*&      SE16起動
*&---------------------------------------------------------------------*
FORM CALL_SE16 USING PI_TABNAME TYPE TABNAME.

  SET PARAMETER ID 'DTB' FIELD PI_TABNAME.
  CALL TRANSACTION 'SE16' AND SKIP FIRST SCREEN.

ENDFORM.                                                    " CALL_SE16
*&---------------------------------------------------------------------*
*&      データ削除
*&---------------------------------------------------------------------*
FORM TABLE_DELETE.

  DATA: LT_COND      LIKE STANDARD TABLE OF WHERE_TAB,
        LST_FIT00004 TYPE TY_FIT00004,
        LW_MESSAGE   TYPE STRING.

  FREE: LT_COND.
  IF T_WHERE-TABLENAME = P_TSTR
  AND LINES( T_WHERE-WHERE_TAB ) IS NOT INITIAL.
    LT_COND[] = T_WHERE-WHERE_TAB[].
  ELSE.
*   動的条件を設定する
    PERFORM COND_SET USING P_TSTR
                           '削除範囲の選択'
                  CHANGING T_WHERE.
    LT_COND[] = T_WHERE-WHERE_TAB[].
  ENDIF.

  SELECT COUNT(*) FROM (P_TSTR) WHERE (LT_COND[]).

  IF SY-DBCNT > 0.
    IF LT_COND[] IS INITIAL.
      MESSAGE S398 WITH '削除対象は、全件です' '' '' ''
                   INTO LW_MESSAGE.
    ELSE.
      MESSAGE S398 WITH '削除対象は、' SY-DBCNT '件です' ''
                   INTO LW_MESSAGE.
    ENDIF.
    CONDENSE LW_MESSAGE.

    PERFORM POPUP_TO_CONFIRM USING '削除確認'
                                   LW_MESSAGE
                                   '本当に削除しますか？'
                                   '2' 'Q'
                          CHANGING W_ANSWER.
    IF  W_ANSWER  <>  '1'.
      MESSAGE S398 WITH '削除を中止しました' '' '' ''. STOP.
    ENDIF.
  ELSE.
    MESSAGE S398 WITH '対象データがありません' '' '' ''. STOP.
  ENDIF.

  PERFORM DISPLAY_INDICATOR USING 100 0
          '削除中。しばらくお待ち下さい...' ''.

* データ削除
  DELETE  FROM  (P_TSTR)  WHERE  (LT_COND[]).

  IF SY-SUBRC = 0.
    MESSAGE S398 WITH 'ﾃｰﾌﾞﾙ削除(件数 = ' SY-DBCNT '件)' ''.
    LST_FIT00004-MANDT      = SY-MANDT.        "クライアント
    LST_FIT00004-UPDATE_TBL = P_TSTR.          "テーブル名
    LST_FIT00004-UPDATE_DT  = SY-DATUM.        "更新日付
    LST_FIT00004-UPDATE_TM  = SY-UZEIT.        "更新時刻
    LST_FIT00004-USERID     = SY-UNAME.        "ユーザーID
    LST_FIT00004-ACTION     = 'DELETE'.        "アクション
    LST_FIT00004-UPDATE_CNT = SY-DBCNT.        "更新件数
    LST_FIT00004-ANPRG      = SY-CPROG.        "登録プログラム
    LST_FIT00004-ANDAT      = SY-DATUM.        "登録日
    LST_FIT00004-ANUZT      = SY-UZEIT.        "登録時刻
    LST_FIT00004-ANNAM      = SY-UNAME.        "登録ユーザ
    LST_FIT00004-AEPRG      = SY-CPROG.        "最終更新プログラム
    LST_FIT00004-AEDAT      = SY-DATUM.        "最終更新日
    LST_FIT00004-AEZET      = SY-UZEIT.        "最終更新時刻
    LST_FIT00004-AENAM      = SY-UNAME.        "最終更新ユーザ
    INSERT /SH3/FIT00004 FROM LST_FIT00004.
*   登録に失敗した場合
    IF SY-SUBRC <> 0.
      ROLLBACK WORK.
*     &1の登録に失敗しました
      MESSAGE S004(/SH3/SSN) WITH 'テーブル一括UL ログテーブル'.
      STOP.
    ENDIF.
    COMMIT WORK.
  ELSE.
    MESSAGE S398 WITH 'ﾃｰﾌﾞﾙ削除ERROR(RC:' SY-SUBRC ')' ''.
    ROLLBACK WORK.
    STOP.
  ENDIF.

ENDFORM.                    " TABLE_DELETE
*&---------------------------------------------------------------------*
*&      エラーメッセージ編集
*&---------------------------------------------------------------------*
*       -->PI_SEQ     連番
*       -->PI_FLDNAM  項目名
*       -->PI_VALUE   項目値
*       -->PI_ERR_CD  エラー種類
*----------------------------------------------------------------------*
FORM SET_ERR_MSG USING PI_SEQ_NO TYPE ANY
                       PI_FLDNAM TYPE ANY
                       PI_VALUE  TYPE ANY
                       PI_ERR_CD TYPE ANY.

  CHECK PI_ERR_CD <> ' '
  AND   PI_ERR_CD <> '0'.

  CLEAR: T_ERR_MSG.
  T_ERR_MSG-SEQ  = PI_SEQ_NO.
  T_ERR_MSG-ITEM = PI_FLDNAM.

  IF PI_VALUE IS NOT INITIAL.
    T_ERR_MSG-VAL = PI_VALUE.
  ENDIF.

  CASE PI_ERR_CD.
    WHEN '1'.
      T_ERR_MSG-MSG = '数値変換エラーの為、ゼロに置換されました'.
    WHEN '2'.
      T_ERR_MSG-MSG = '日付変換エラーの為、初期値に置換されました'.
    WHEN '3'.
      T_ERR_MSG-MSG = 'CONVERSION EXIT変換エラーです'.
    WHEN '4'.
      T_ERR_MSG-MSG = 'データ型変換エラーまたはオーバーフローです'.
    WHEN '5'.
      T_ERR_MSG-MSG = '項目名が存在しません'.
    WHEN '6'.
      T_ERR_MSG-MSG = '<仮数>E<指数>形式のテキストで入力して下さい'.
    WHEN '7'.
      T_ERR_MSG-MSG = '16進数以外の文字が含まれています'.
    WHEN '8'.
      T_ERR_MSG-MSG = '時刻変換エラーの為、初期値に置換されました'.
    WHEN OTHERS.
  ENDCASE.

  APPEND T_ERR_MSG.

ENDFORM.                    " SET_ERR_MSG
*&---------------------------------------------------------------------*
*&      アップロード エラーログ出力
*&---------------------------------------------------------------------*
FORM UPLOAD_LOG .

  CHECK RB_ET = C_ON.
  CHECK CB_LOG = C_ON.

  LOOP AT T_ERR_MSG.
    WRITE: /001(008)  T_ERR_MSG-SEQ,
            011(020)  T_ERR_MSG-ITEM,
            035(020)  T_ERR_MSG-VAL,
            060(100)  T_ERR_MSG-MSG.
  ENDLOOP.

ENDFORM.                    " UPLOAD_LOG
*&---------------------------------------------------------------------*
*&      テーブル情報取得
*&---------------------------------------------------------------------*
*      -->PT_DFIES   透過テーブル項目情報
*      -->PI_TABNAM  テーブル名
*----------------------------------------------------------------------*
FORM GET_DD_INFO TABLES PT_DFIES  STRUCTURE DFIES
                  USING PI_TABNAM LIKE DFIES-TABNAME
                        PI_FLDNAM LIKE DFIES-FIELDNAME.

  FREE: PT_DFIES.

  CALL FUNCTION 'DDIF_FIELDINFO_GET'                        "#EC *
    EXPORTING
      TABNAME        = PI_TABNAM
      FIELDNAME      = PI_FLDNAM
      LANGU          = SY-LANGU
    TABLES
      DFIES_TAB      = PT_DFIES
    EXCEPTIONS
      NOT_FOUND      = 1
      INTERNAL_ERROR = 2
      OTHERS         = 3.

  CHECK PI_FLDNAM IS INITIAL.

  IF SY-SUBRC = 0.
    SORT PT_DFIES BY POSITION.
  ELSE.
    MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO DISPLAY LIKE 'E'
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    STOP.
  ENDIF.

ENDFORM.                    " GET_DD_INFO
*&---------------------------------------------------------------------*
*&      環境変数を取得
*&---------------------------------------------------------------------*
*      -->PI_ENV    環境変数名
*      <--PO_VALUE  取得値
*----------------------------------------------------------------------*
FORM GET_ENVIRONMENT USING PI_ENV   TYPE ANY
                  CHANGING PO_VALUE TYPE ANY.

  DATA: LW_ENV TYPE STRING,
        LW_VAL TYPE STRING.

  LW_ENV = PI_ENV.

* 環境変数を取得
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>ENVIRONMENT_GET_VARIABLE
    EXPORTING
      VARIABLE             = LW_ENV
    CHANGING
      VALUE                = LW_VAL
    EXCEPTIONS
      CNTL_ERROR           = 1
      ERROR_NO_GUI         = 2
      NOT_SUPPORTED_BY_GUI = 3
      OTHERS               = 4.

* バッファした自動キューをフロントエンドに送信
  CALL METHOD CL_GUI_CFW=>FLUSH.

  IF SY-SUBRC = 0.
    PO_VALUE = LW_VAL.
*    nDone = 1.
  ELSE.
    CLEAR: PO_VALUE.
*    nDone = -1.
  ENDIF.

ENDFORM.                    " GET_ENVIRONMENT
*&---------------------------------------------------------------------*
*&      テキスト分割(全角対応)
*&---------------------------------------------------------------------*
*      -->PI_TEXT   元テキスト
*      -->PI_LENG   PO_TEXT1への出力長(0:定義長)
*      -->PI_SPLIT  分割位置調整文字
*      <--PO_TEXT1  分割後テキスト
*      <--PO_TEXT2  残テキスト
*----------------------------------------------------------------------*
FORM TEXT_SPLIT USING PI_TEXT  TYPE CLIKE
                      PI_LENG  TYPE I
                      PI_SPLIT TYPE SYCHAR01
             CHANGING PO_TEXT1 TYPE C
                      PO_TEXT2 TYPE CLIKE.

  DATA: LW_LENG  TYPE I,
        LW_FDPOS LIKE SY-FDPOS.

  CHECK PI_TEXT IS NOT INITIAL.

* 分割位置Check
  DESCRIBE FIELD PO_TEXT1 LENGTH LW_LENG IN BYTE MODE.
  IF PI_LENG IS NOT INITIAL
  AND PI_LENG < LW_LENG.
    LW_LENG = PI_LENG.
  ENDIF.

* 分割位置調整
  IF LW_LENG < STRLEN( PI_TEXT )
  AND PI_SPLIT IS NOT INITIAL.
    LW_FDPOS = LW_LENG.
    WHILE LW_FDPOS > 0.
      IF PI_SPLIT = '\' OR PI_SPLIT = '/'.
        IF PI_TEXT+LW_FDPOS(1) = '\'
        OR PI_TEXT+LW_FDPOS(1) = '/'.
          EXIT.
        ENDIF.
      ELSE.
        IF PI_TEXT+LW_FDPOS(1) = PI_SPLIT.
          EXIT.
        ENDIF.
      ENDIF.
      LW_FDPOS = LW_FDPOS - 1.
    ENDWHILE.
    IF LW_FDPOS > 0.
      LW_LENG = LW_FDPOS.
    ENDIF.
  ENDIF.

* テキスト分割
  CALL FUNCTION 'TEXT_SPLIT'
    EXPORTING
      LENGTH = LW_LENG
      TEXT   = PI_TEXT
*     AS_CHARACTER =
    IMPORTING
      LINE   = PO_TEXT1
      REST   = PO_TEXT2.

ENDFORM.                    " TEXT_SPLIT
*&---------------------------------------------------------------------*
*       レンジテーブルの設定
*----------------------------------------------------------------------*
*      <--PT_RANGE   レンジテーブル
*      -->PI_SIGN    I:包含/E:除外
*      -->PI_OPTION  演算子(EQ/BT/CP/LT/GT...)
*      -->PI_LOW     下限値
*      -->PI_HIGH    上限値
*----------------------------------------------------------------------*
FORM SET_RANGES_DATA TABLES PT_RANGES
                      USING PI_SIGN   TYPE DDSIGN
                            PI_OPTION TYPE DDOPTION
                            PI_LOW    TYPE ANY
                            PI_HIGH   TYPE ANY.

  FIELD-SYMBOLS: <LFS_SIGN>,
                 <LFS_OPTION>,
                 <LFS_LOW>,
                 <LFS_HIGH>.

  ASSIGN COMPONENT 1 OF STRUCTURE PT_RANGES TO <LFS_SIGN>.
  ASSIGN COMPONENT 2 OF STRUCTURE PT_RANGES TO <LFS_OPTION>.
  ASSIGN COMPONENT 3 OF STRUCTURE PT_RANGES TO <LFS_LOW>.
  ASSIGN COMPONENT 4 OF STRUCTURE PT_RANGES TO <LFS_HIGH>.

  CLEAR: PT_RANGES.
  <LFS_SIGN>   = PI_SIGN.
  <LFS_OPTION> = PI_OPTION.
  IF PI_LOW  IS NOT INITIAL.
    <LFS_LOW>    = PI_LOW.
  ENDIF.
  IF PI_HIGH IS NOT INITIAL.
    <LFS_HIGH>   = PI_HIGH.
  ENDIF.
  APPEND PT_RANGES.

ENDFORM.                    " SET_RANGES_DATA
*&---------------------------------------------------------------------*
*&      進捗率表示
*&---------------------------------------------------------------------*
*      -->PI_MAXCNT  基準値
*      -->PI_NOW     現在値
*      -->PI_MSG1    メッセージ変数１
*      -->PI_MSG2    メッセージ変数２
*----------------------------------------------------------------------*
FORM DISPLAY_INDICATOR USING PI_MAXCNT TYPE I
                             PI_NOW    TYPE I
                             PI_MSG1   TYPE C
                             PI_MSG2   TYPE C.

  STATICS: LW_MAX   TYPE I,                 "基準値
           LW_CNT   TYPE I.                 "表示済み進捗率
  DATA: LW_WORK TYPE I,                 "進捗率
        LW_NEXT TYPE I,                 "次回表示進捗率
        LW_MSG  TYPE STRING.

* 初期表示処理
  IF PI_MAXCNT <> LW_MAX
  OR PI_NOW    IS INITIAL.
    CLEAR: LW_CNT.
    LW_MAX = PI_MAXCNT.
  ENDIF.

  CHECK LW_CNT < 100.

* 進捗率算出
  LW_WORK = PI_NOW * 100 DIV PI_MAXCNT.

* 前回表示率から１０%以上増加した場合、処理続行
  LW_NEXT = LW_CNT + 10.
  CHECK LW_WORK >= LW_NEXT
     OR PI_NOW  =  0.                       "初期表示

* 表示内容の編集
  LW_CNT = LW_WORK DIV 10 * 10.                             "10%単位
  MESSAGE S398 WITH LW_CNT '%:' PI_MSG1 PI_MSG2
    INTO LW_MSG.

* 進捗率表示
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      PERCENTAGE = LW_CNT
      TEXT       = LW_MSG.

ENDFORM.                    " DISPLAY_INDICATOR
*&---------------------------------------------------------------------*
*&      Form  CHECK_LAYOUT
*&---------------------------------------------------------------------*
*       項目数チェック
*----------------------------------------------------------------------*
FORM CHECK_LAYOUT .

  DATA: LT_DATA    LIKE T_ITEM,
        LW_TBL_CNT TYPE I,
        LW_DAT_CNT TYPE I.

  FIELD-SYMBOLS: <FS_EXCEL> TYPE STRING.

* テーブル項目数
  IF T_FIELD-FLD_RANGE[] IS INITIAL.
    LW_TBL_CNT = LINES( T_DD03L ).
    IF W_CLNT_FLG = C_ON.
      LW_TBL_CNT = LW_TBL_CNT - 1.
    ENDIF.
  ELSE.
    LW_TBL_CNT = LINES( T_FIELD-FLD_RANGE ).
  ENDIF.

* 入力ファイル項目数
  READ TABLE T_EXCEL ASSIGNING <FS_EXCEL> INDEX 1.
  CHECK SY-SUBRC = 0.
  SPLIT <FS_EXCEL> AT W_SPLIT INTO TABLE LT_DATA.
  LW_DAT_CNT = LINES( LT_DATA ).

* 項目数チェック
  IF LW_DAT_CNT <> LW_TBL_CNT.
    PERFORM POPUP_TO_CONFIRM USING 'ファイル確認'
            'テーブルと入力ファイルの項目数が一致しません'
            '処理を続行しますか？'
            '2' 'W'
            CHANGING W_ANSWER.
    IF W_ANSWER <> '1'.
      MESSAGE S398 DISPLAY LIKE 'E'
              WITH '処理を中止しました' '' '' ''.
      STOP.
    ENDIF.
  ENDIF.

ENDFORM.                    " CHECK_LAYOUT

*&---------------------------------------------------------------------*
*&      Form  CONV_DATA_CURR_OUT
*&---------------------------------------------------------------------*
*&      ダウンロードの通貨コードより金額の変換
*&---------------------------------------------------------------------*
*      -->PI_DD03L      T_DD03Lテーブルの構成
*      -->PI_TAB_LINE   抽出データ
*      -->PI_DATA       変換前の金額
*      <--PO_DATA       変換後の金額
*----------------------------------------------------------------------*
FORM CONV_DATA_CURR_OUT  TABLES  PI_DD03L     STRUCTURE DFIES
                          USING  PI_TAB_LINE  TYPE ANY
                                 PI_DATA      TYPE ANY
                       CHANGING  PO_DATA      TYPE ANY.

* 変数
  DATA: LW_DATA      LIKE BAPICURR-BAPICURR,   "変換後の金額
        LW_WAERS(30) TYPE C,
        H_T_DD03L    LIKE LINE OF PI_DD03L.    "T_DD03Lテーブルの構造

  FIELD-SYMBOLS: <F_WAERS>.                    "通貨コード

  CLEAR: PO_DATA.
* 通貨コードを抽出する
  IF PI_DD03L-TABNAME = PI_DD03L-REFTABLE.
    CONCATENATE 'PI_TAB_LINE-' PI_DD03L-REFFIELD INTO LW_WAERS.
    ASSIGN (LW_WAERS) TO <F_WAERS>.
*   通貨コードを'JPY'に設定する
    IF <F_WAERS> IS INITIAL.
      ASSIGN C_WAERS_J  TO <F_WAERS>.
    ENDIF.
  ELSE.
    ASSIGN C_WAERS_J  TO <F_WAERS>.
  ENDIF.
* 金額変換
  WRITE PI_DATA TO PO_DATA CURRENCY <F_WAERS> NO-GAP NO-GROUPING.
ENDFORM.                    "CONV_DATA_CURR_OUT
*&---------------------------------------------------------------------*
*&      Form  CONV_DATA_CURR_IN
*&---------------------------------------------------------------------*
*&      アップロードの通貨コードより金額の変換
*&---------------------------------------------------------------------*
*      -->PI_ITEM       読込データ
*      -->PI_DD03L      T_DD03Lテーブルの構成
*      -->PI_DATA       変換前の金額
*      <--PO_DATA       変換後の金額
*----------------------------------------------------------------------*
FORM CONV_DATA_CURR_IN TABLES   PI_ITEM           "STRING
                                PI_DD03L STRUCTURE DFIES
                        USING   PI_DATA  TYPE ANY
                                PI_SEQ   TYPE ANY
                                PI_TEXT  TYPE CLIKE
                                PI_ERRCD TYPE ANY
                     CHANGING   PO_DATA  TYPE ANY.

* 変数
  DATA: LW_POS       TYPE I,                   "データ読込用索引
        LW_WAERS_UP  LIKE TCURC-WAERS,         "通貨コード
        LW_LENG      TYPE I,                   "金額の桁数
        LW_PI_DATA   LIKE BAPICURR-BAPICURR,   "変換前の金額
        H_T_DD03L    LIKE LINE OF PI_DD03L,    "T_DD03Lテーブルの構造
        LW_DEC_LEN   TYPE I,
        LW_DATA_LEN  TYPE I,
        LW_DO_NUM(2) TYPE N,
        LW_WORK_LEN  TYPE I.

  CLEAR: H_T_DD03L.

* 金額の桁数
  LW_LENG = PI_DD03L-LENG.
* DBデータの長さ取得
  LW_DATA_LEN = PI_DD03L-LENG.
* DBデータ小数部分の長さ取得
  LW_DEC_LEN  = PI_DD03L-DECIMALS.
* DBデータ整数部分の長さ計算
  LW_DATA_LEN = PI_DD03L-LENG - PI_DD03L-DECIMALS.
* ファイルのデータの長さ取得
  LW_WORK_LEN = STRLEN( PI_DATA ) - 1.

* ファイルのデータの値がNULLまたは0の判断
  IF LW_WORK_LEN = -1 OR PI_DATA = 0.
    PO_DATA = PI_DATA.
  ELSE.
*   ファイルのデータの整数部分の長さ取得
    DO.
      IF '0123456789' CS PI_DATA+LW_DO_NUM(1).
      ELSE.
        EXIT.
      ENDIF.
      IF LW_DO_NUM = LW_WORK_LEN.
        LW_DO_NUM = LW_DO_NUM + 1.
        EXIT.
      ENDIF.
      LW_DO_NUM = LW_DO_NUM + 1.
    ENDDO.
*   金額書式変換
    IF PI_DD03L-DATATYPE = C_CURR.
* 　  金額の項目チェック
      IF CB_CHAN = C_ON.
        TRY.
            LW_PI_DATA = PI_DATA.

**          通貨コードを抽出する
            IF PI_DD03L-TABNAME = PI_DD03L-REFTABLE.
              LOOP AT PI_DD03L INTO H_T_DD03L.
                IF H_T_DD03L-FIELDNAME = PI_DD03L-REFFIELD.
                  CLEAR: LW_WAERS_UP.
**                ファイルの通貨コードを抽出する
                  LW_POS = H_T_DD03L-POSITION - 1.
                  READ TABLE PI_ITEM INTO LW_WAERS_UP INDEX LW_POS.
                  IF LW_WAERS_UP IS INITIAL.
**                  通貨コードを'JPY'に設定する
                    LW_WAERS_UP = C_WAERS_J.
                  ENDIF.
                  EXIT.
                ELSE.
                  LW_WAERS_UP = C_WAERS_J.
                ENDIF.
              ENDLOOP.
            ELSE.
              LW_WAERS_UP = C_WAERS_J.
            ENDIF.
**          金額変換
            CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_INTERNAL'
              EXPORTING
                CURRENCY             = LW_WAERS_UP
                AMOUNT_EXTERNAL      = LW_PI_DATA
                MAX_NUMBER_OF_DIGITS = LW_LENG
              IMPORTING
                AMOUNT_INTERNAL      = PO_DATA.
**          変換判断
            IF PI_DATA <> 0 AND PO_DATA IS INITIAL.
              PERFORM SET_ERR_MSG
                  USING PI_SEQ PI_TEXT PI_DATA PI_ERRCD.
            ENDIF.
          CATCH CX_SY_CONVERSION_ERROR
                   CX_SY_ARITHMETIC_OVERFLOW
                   CX_SY_MOVE_CAST_ERROR.
            PERFORM SET_ERR_MSG
                  USING PI_SEQ PI_TEXT PI_DATA PI_ERRCD.
        ENDTRY.
      ELSE.
*       データ長すぎる判断
        IF LW_DO_NUM > LW_DATA_LEN.
          PERFORM SET_ERR_MSG
                    USING PI_SEQ PI_TEXT PI_DATA PI_ERRCD.
        ELSE.
          PO_DATA = PI_DATA.
        ENDIF.
      ENDIF.
    ELSE.
*     データ長すぎる判断
      IF LW_DO_NUM > LW_DATA_LEN.
        PERFORM SET_ERR_MSG
                  USING PI_SEQ PI_TEXT PI_DATA PI_ERRCD.
      ELSE.
        PO_DATA = PI_DATA.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    "CONV_DATA_CURR_IN
*&---------------------------------------------------------------------*
*&      Form  CHECK_CAT0001
*&---------------------------------------------------------------------*
*       更新・削除対象外のチェック
*----------------------------------------------------------------------*
FORM CHECK_CAT0001 .

* 変数の定義
  DATA:
    LTA_RANGE TYPE TY_R_CATSS01.  "汎用パラメータテーブルのRANGEテーブル

* 汎用パラメータの取得
  CALL FUNCTION '/SH3/GET_TBL_CAT0001'
    EXPORTING
      I_SELECT_TYPE  = 'R'        "セレクトタイプ
      I_PROGRAMM     = SY-CPROG   "ABAP プログラム名
      I_ZSELID       = 'P_TSTR'   "項目ID
    TABLES
      T_RANGETABLE   = LTA_RANGE  "汎用パラメータテーブルのRANGEテーブル
    EXCEPTIONS
      PARAMETER_ERROR = 1
      NOT_FOUND       = 2
      SYSTEM_ERROR    = 3
      OTHERS          = 4.

* 取得に失敗した場合
  IF SY-SUBRC <> 0.

*   汎用パラメータ取得に失敗しました。 キー: &1 &2 &3 &4
    MESSAGE S017(/SH3/SSN) DISPLAY LIKE 'E'
            WITH 'R' SY-CPROG 'P_TSTR' ''.
    STOP.

  ENDIF.

* テーブルIDのチェック処理
* テーブルIDに入力された内容　IN　汎用パラメータのLOW値の場合
  IF P_TSTR IN LTA_RANGE.

*   処理選択がアップロードの場合
    IF RB_ET  = 'X'.

*     & & & &
      MESSAGE S999(/SH3/FIN) DISPLAY LIKE 'E'
              WITH 'テーブルID：'
                   P_TSTR
                   'は、この機能で更新できません'
                   ''.
      STOP.

    ENDIF.

*   処理選択がデータ削除の場合
    IF RB_DEL = 'X'.

*     & & & &
      MESSAGE S999(/SH3/FIN) DISPLAY LIKE 'E'
              WITH 'テーブルID：'
                   P_TSTR
                   'は、この機能で削除できません'
                   ''.
      STOP.

    ENDIF.

  ENDIF.

ENDFORM.                    "CHECK_CAT0001
*&---------------------------------------------------------------------*
*&      Form  MODIFY_FIT00004
*&---------------------------------------------------------------------*
*       テーブル一括UL ログテーブル（/SH3/FIT00004）の更新
*----------------------------------------------------------------------*
*      -->PI_MOD             登録（INSERT）/更新（UPDATE）
*      -->PI_TO              処理件数
*      -->PI_TABNM           テーブル名
*      <--PO_ST_FIT00004     対象処理ステータス
*----------------------------------------------------------------------*
FORM MODIFY_FIT00004 USING PI_MOD         TYPE C
                           PI_TO          TYPE I
                           PI_TABNM       LIKE RSEDD0-DDOBJNAME
                  CHANGING PO_ST_FIT00004 TYPE TY_FIT00004.

* 登録（INSERT）の場合
  IF PI_MOD = 'I'.

    PO_ST_FIT00004-UPDATE_CNT = PI_TO.             "更新件数

*   １処理の処理で１レコード登録する
    INSERT /SH3/FIT00004 FROM PO_ST_FIT00004.

* 更新（UPDATE）の場合
  ELSE.

*   ２回目以降のコミットを行う場合、
*   １回目に登録したレコードに対し更新（UPDATE）する
    UPDATE /SH3/FIT00004
       SET UPDATE_CNT = PI_TO                      "更新件数
           AEPRG      = SY-CPROG                   "最終更新プログラム
           AEDAT      = SY-DATUM                   "最終更新日
           AEZET      = SY-UZEIT                   "最終更新時刻
           AENAM      = SY-UNAME                   "最終更新ユーザ
     WHERE UPDATE_TBL = PO_ST_FIT00004-UPDATE_TBL  "テーブル名
       AND UPDATE_DT  = PO_ST_FIT00004-UPDATE_DT   "更新日付
       AND UPDATE_TM  = PO_ST_FIT00004-UPDATE_TM   "更新時刻
       AND USERID     = PO_ST_FIT00004-USERID.     "ユーザーID

  ENDIF.

* 登録/更新に成功した場合
  IF SY-SUBRC = 0.

    COMMIT WORK.

* 登録/更新に失敗した場合
  ELSE.

    ROLLBACK WORK.
*   &1の登録に失敗しました
    MESSAGE S004(/SH3/SSN) WITH 'テーブル一括UL ログテーブル'.
    STOP.

  ENDIF.


ENDFORM.                    "MODIFY_FIT00004
