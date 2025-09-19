*&---------------------------------------------------------------------*
*& Report ZBRK3_USER_TYPE_LOG_MAIL
*&---------------------------------------------------------------------*
REPORT zbrk3_user_type_log_mail.

TABLES: adr6, ush02.

PARAMETERS: p_day TYPE i OBLIGATORY DEFAULT 1.
SELECT-OPTIONS: p_email FOR adr6-smtp_addr NO INTERVALS.

DATA: lt_mail_body TYPE TABLE OF soli,
      lv_subject   TYPE so_obj_des.

" Filtrelenmiş logları ve önceki tipi tutacak yapı
TYPES: BEGIN OF ty_filtered_data,
         bname        TYPE ush02-bname,
         modda        TYPE ush02-modda,
         modti        TYPE ush02-modti,
         modbe        TYPE ush02-modbe,
         ustyp        TYPE ush02-ustyp,
         onceki_ustyp TYPE ush02-ustyp,
       END OF ty_filtered_data.

DATA: lt_filtered_user_data TYPE TABLE OF ty_filtered_data.

START-OF-SELECTION.
  DATA(lv_start_date) = sy-datum - p_day.

  "USH02'den logları çekme
  SELECT bname, modda, modti, modbe, ustyp
    FROM ush02
    INTO TABLE @DATA(lt_user_data)
    WHERE modda BETWEEN @lv_start_date AND @sy-datum
    ORDER BY bname, modda, modti.

  IF lt_user_data IS NOT INITIAL.
    "Sadece USTYP alanı değişmiş logları filtreleme
    LOOP AT lt_user_data INTO DATA(ls_log).
      SELECT ustyp
        FROM ush02
        INTO @DATA(lv_onceki_ustyp)
        UP TO 1 ROWS
        WHERE bname = @ls_log-bname
          AND ( modda < @ls_log-modda OR
                ( modda = @ls_log-modda AND modti < @ls_log-modti ) )
        ORDER BY modda DESCENDING, modti DESCENDING.
      ENDSELECT.

      IF sy-subrc = 0 AND ls_log-ustyp <> lv_onceki_ustyp.
        APPEND VALUE #(
          bname        = ls_log-bname
          modda        = ls_log-modda
          modti        = ls_log-modti
          modbe        = ls_log-modbe
          ustyp        = ls_log-ustyp
          onceki_ustyp = lv_onceki_ustyp
        ) TO lt_filtered_user_data.
      ENDIF.
    ENDLOOP.

    "HTML raporu oluşturma ve mail gönderme
    IF lt_filtered_user_data IS NOT INITIAL.
      "HTML Stil (CSS)
      APPEND '<html><head><style>' TO lt_mail_body.
      APPEND 'table { border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; }' TO lt_mail_body.
      APPEND 'th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }' TO lt_mail_body.
*      APPEND 'th { background-color: #f2f2f2; text-transform: uppercase; }' TO lt_mail_body.
      APPEND 'th { background-color: #343a40; color: white; text-transform: uppercase; }' TO lt_mail_body.
      APPEND '</style></head><body>' TO lt_mail_body.

      "Rapor Başlığı
      APPEND '<h2>Kullanıcı Tipi Değişiklik Raporu</h2>' TO lt_mail_body.
      APPEND '<table>' TO lt_mail_body.

      "HTML Başlıklarını Oluşturma
      APPEND '<tr>' TO lt_mail_body.
      APPEND '<th>KULLANICI</th>' TO lt_mail_body.
      APPEND '<th>ESKİ TİP</th>' TO lt_mail_body.
      APPEND '<th>SONRAKİ TİP</th>' TO lt_mail_body.
      APPEND '<th>DEĞİŞTİREN</th>' TO lt_mail_body.
      APPEND '<th>TARİH</th>' TO lt_mail_body.
      APPEND '<th>ZAMAN</th>' TO lt_mail_body.
      APPEND '</tr>' TO lt_mail_body.

      " Veri Satırlarını Oluşturma
      LOOP AT lt_filtered_user_data INTO DATA(ls_user_data).
        DATA: lv_onceki_text  TYPE string,
              lv_sonraki_text TYPE string,
              lv_fullname     TYPE bapiaddr3-fullname,
              ls_address      TYPE bapiaddr3,      " BAPI'den dönecek adres yapısı
              lt_return       TYPE bapirettab.      " BAPI'den dönecek mesaj tablosu


        APPEND '<tr style="background-color: #f8f9fa;">' TO lt_mail_body.

        " Kullanıcı Adı
        APPEND |<td>{ ls_user_data-bname }</td>| TO lt_mail_body.

        " Önceki Tip
        PERFORM get_ustyp_text USING ls_user_data-onceki_ustyp CHANGING lv_onceki_text.
        APPEND |<td style="background-color: #ced4da;">{ lv_onceki_text }</td>| TO lt_mail_body.

        " Sonraki Tip (Mevcut Tip)
        PERFORM get_ustyp_text USING ls_user_data-ustyp CHANGING lv_sonraki_text.
        APPEND |<td style="background-color: #d1e7dd;">{ lv_sonraki_text }</td>| TO lt_mail_body.


        CALL FUNCTION 'BAPI_USER_GET_DETAIL'
          EXPORTING
            username = ls_user_data-modbe
          IMPORTING
            address  = ls_address
          TABLES
            return   = lt_return.

        READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0 AND ls_address-fullname IS NOT INITIAL.
          lv_fullname = ls_address-fullname.
        ELSE.
          lv_fullname = ls_user_data-modbe.
        ENDIF.
        APPEND |<td>{ lv_fullname }</td>| TO lt_mail_body.

        "Tarih
        DATA lv_tarih_readable(10) TYPE c.
        WRITE ls_user_data-modda TO lv_tarih_readable DD/MM/YYYY.
        APPEND |<td>{ lv_tarih_readable }</td>| TO lt_mail_body.

        "Zaman
        DATA lv_zaman_readable(8) TYPE c.
        WRITE ls_user_data-modti TO lv_zaman_readable USING EDIT MASK '__:__:__'.
        APPEND |<td>{ lv_zaman_readable }</td>| TO lt_mail_body.

        APPEND '</tr>' TO lt_mail_body.
      ENDLOOP.

      APPEND '</table></body></html>' TO lt_mail_body.

      " Mail Gönderme
      TRY.
          lv_subject = |Kullanıcı Değişiklik Raporu - { sy-datum DATE = USER }|.
          DATA(lo_bcs) = cl_bcs=>create_persistent( ).
          DATA(lo_document) = cl_document_bcs=>create_document(
            i_type    = 'HTM'
            i_text    = lt_mail_body
            i_subject = lv_subject
          ).
          lo_bcs->set_document( lo_document ).

          LOOP AT p_email INTO DATA(ls_mail).
            DATA(lv_mail) = ls_mail-low.
            DATA(lo_recipient) = cl_cam_address_bcs=>create_internet_address( lv_mail ).
            lo_bcs->add_recipient( i_recipient = lo_recipient ).
          ENDLOOP.

          lo_bcs->send( ).
          COMMIT WORK.
          WRITE: / 'E-posta başarıyla gönderildi.'.
        CATCH cx_bcs INTO DATA(lx_bcs).
          WRITE: / 'Hata:', lx_bcs->get_text( ).
      ENDTRY.
    ELSE.
      MESSAGE 'Belirtilen kriterlere uygun kullanıcı tipi değişikliği bulunamadı.' TYPE 'S' DISPLAY LIKE 'I'.
    ENDIF.
  ENDIF.

FORM get_ustyp_text USING iv_ustyp TYPE ush02-ustyp CHANGING cv_text TYPE string.
  CASE iv_ustyp.
    WHEN 'A'. cv_text = 'A - Diyalog'.
    WHEN 'B'. cv_text = 'B - Sistem'.
    WHEN 'C'. cv_text = 'C - İletişim'.
    WHEN 'L'. cv_text = 'L - Referans'.
    WHEN 'S'. cv_text = 'S - Servis'.
    WHEN OTHERS. cv_text = iv_ustyp.
  ENDCASE.
ENDFORM.
