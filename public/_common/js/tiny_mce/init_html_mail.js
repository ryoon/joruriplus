/**
 * Initializes the tinyMCE.
 */
function initTinyMCE(originalSettings) {
  var settings = {
    // General options
    doctype: '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">',
    language: "ja",
    mode: "specific_textareas",
    editor_selector: "mceEditor",
    theme: "advanced",
    plugins: "table,fullscreen,media,template,preview",
    //plugins: "table,searchreplace,contextmenu,fullscreen,paste,emotions,media,template,preview",

    // Theme options
    theme_advanced_buttons1: "fontselect,fontsizeselect,separator,removeformat,separator,forecolor,backcolor,separator,bold,italic,underline,strikethrough,separator,justifyleft,justifycenter,justifyright,separator,bullist,numlist,separator,outdent,indent,blockquote,separator,link,unlink,separator,code",
    theme_advanced_buttons2: "",
    theme_advanced_buttons3: "",
    theme_advanced_buttons4: "",
    theme_advanced_toolbar_location: "top",
    theme_advanced_toolbar_align: "left",
    theme_advanced_statusbar_location: "bottom",
    theme_advanced_resizing: true,

    force_br_newlines : true,
    force_p_newlines : false,
    forced_root_block : '', // Needed for 3.x

    // Joruri original settings.
    theme_advanced_path: false,
    theme_advanced_font_sizes: "最大=large,大=medium,標準=small,小=x-small",//最小=xx-small
    theme_advanced_blockformats: "h2,h3,h4",
    theme_advanced_statusbar_location : "none",
    indentation: '1em',
    relative_urls: false,
    convert_urls: false,
    remove_script_host : false,
    table_default_border: 1,
    //document_base_url : "./",
    //readonly : true,

    formats: {
      blockquote: {
        block: 'blockquote',
        styles: {
//          'border-style': "none none none solid",
//          'border-width': "2px",
//          'border-color': "silver",
//          'margin': "0px 0px 0px 5px",
//          'padding': "0px 0px 0px 5px"
          'margin': "2px 0px 2px 5px",
          'padding': "0px 0px 0px 5px",
          'border-left-width': "2px",
          'border-left-style': "solid",
          'border-left-color': "silver"
        },
        wrapper: true
      }
    },

    //setup : function(ed) {
    //  ed.onPostProcess.add(function(ed, o) {
    //     o.content = o.content.replace(/<p>/g, '<p style="margin: 0px; padding: 0px;">');
    //  });
    //},

    setup : function(ed) {
      ed.onPreProcess.add(function(ed, o) {
        ed.dom.setStyles(ed.dom.select('p', o.node), {'margin' : '0px', 'padding' : '0px'});
      });
    },

    theme_advanced_fonts : "Pゴシック=ms pgothic,sans-serif;"+
      "P明朝=ms pmincho,serif;"+
      "ゴシック=ms gothic,monospace;"+
      "明朝=ms mincho,serif;"+
      "Sans Serif=sans-serif;"+
      "Serif=serif;"+
      "幅広=arial black,sans-serif;"+
      "幅狭=arial narrow,sans-serif;"+
      "Verdana=verdana,sens-serif;",
      //"Andale Mono=andale mono,times;"+
      //"Arial=arial,helvetica,sans-serif;"+
      //"Arial Black=arial black,avant garde;"+
      //"Book Antiqua=book antiqua,palatino;"+
      //"Comic Sans MS=comic sans ms,sans-serif;"+
      //"Courier New=courier new,courier;"+
      //"Georgia=georgia,palatino;"+
      //"Helvetica=helvetica;"+
      //"Impact=impact,chicago;"+
      //"Symbol=symbol;"+
      //"Tahoma=tahoma,arial,helvetica,sans-serif;"+
      //"Terminal=terminal,monaco;"+
      //"Times New Roman=times new roman,times;"+
      //"Trebuchet MS=trebuchet ms,geneva;"+
      //"Verdana=verdana,geneva;",//+
      //"Webdings=webdings;"+
      //"Wingdings=wingdings, zapf dingbats",

    // Example content CSS (should be your site CSS)
    content_css: "/_common/themes/admin/tiny_mce.css",

    // Drop lists for link/image/media/template dialogs
    template_external_list_url: "/_common/js/tiny_mce/lists/template_list.js",
    external_link_list_url: "/_common/js/tiny_mce/lists/link_list.js",
    external_image_list_url: "/_common/js/tiny_mce/lists/image_list.js",
    media_external_list_url: "/_common/js/tiny_mce/lists/media_list.js",

    // Style formats
    style_formats: [{
      title: 'Bold text',
      inline: 'b'
    }, {
      title: 'Red text',
      inline: 'span',
      styles: {
        color: '#ff0000'
      }
    }, {
      title: 'Red header',
      block: 'h1',
      styles: {
        color: '#ff0000'
      }
    }, {
      title: 'Example 1',
      inline: 'span',
      classes: 'example1'
    }, {
      title: 'Example 2',
      inline: 'span',
      classes: 'example2'
    }, {
      title: 'Table styles'
    }, {
      title: 'Table row 1',
      selector: 'tr',
      classes: 'tablerow1'
    }],

    // Replace values for the template plugin
    template_replace_values: {      //username : "Some User",
      //staffid : "991234"
    }

    //  valid_elements : ""
    //  +"a[accesskey|charset|class|coords|dir<ltr?rtl|href|hreflang|id|lang|name"
    //    +"|onblur|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup"
    //    +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|rel|rev"
    //    +"|shape<circle?default?poly?rect|style|tabindex|title|target|type],"
    //  +"abbr[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"acronym[class|dir<ltr?rtl|id|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"address[class|align|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
    //    +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
    //    +"|onmouseup|style|title],"
    //  +"applet[align<bottom?left?middle?right?top|alt|archive|class|code|codebase"
    //    +"|height|hspace|id|name|object|style|title|vspace|width],"
    //  +"area[accesskey|alt|class|coords|dir<ltr?rtl|href|id|lang|nohref<nohref"
    //    +"|onblur|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup"
    //    +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup"
    //    +"|shape<circle?default?poly?rect|style|tabindex|title|target],"
    //  +"base[href|target],"
    //  +"basefont[color|face|id|size],"
    //  +"bdo[class|dir<ltr?rtl|id|lang|style|title],"
    //  +"big[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"blockquote[cite|class|dir<ltr?rtl|id|lang|onclick|ondblclick"
    //    +"|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout"
    //    +"|onmouseover|onmouseup|style|title],"
    //  +"body[alink|background|bgcolor|class|dir<ltr?rtl|id|lang|link|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onload|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|onunload|style|title|text|vlink],"
    //  +"br[class|clear<all?left?none?right|id|style|title],"
    //  +"button[accesskey|class|dir<ltr?rtl|disabled<disabled|id|lang|name|onblur"
    //    +"|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup|onmousedown"
    //    +"|onmousemove|onmouseout|onmouseover|onmouseup|style|tabindex|title|type"
    //    +"|value],"
    //  +"caption[align<bottom?left?right?top|class|dir<ltr?rtl|id|lang|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"center[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"cite[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"code[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"col[align<center?char?justify?left?right|char|charoff|class|dir<ltr?rtl|id"
    //    +"|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown"
    //    +"|onmousemove|onmouseout|onmouseover|onmouseup|span|style|title"
    //    +"|valign<baseline?bottom?middle?top|width],"
    //  +"colgroup[align<center?char?justify?left?right|char|charoff|class|dir<ltr?rtl"
    //    +"|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown"
    //    +"|onmousemove|onmouseout|onmouseover|onmouseup|span|style|title"
    //    +"|valign<baseline?bottom?middle?top|width],"
    //  +"dd[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
    //    +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"del[cite|class|datetime|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
    //    +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
    //    +"|onmouseup|style|title],"
    //  +"dfn[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"dir[class|compact<compact|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
    //    +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
    //    +"|onmouseup|style|title],"
    //  +"div[align<center?justify?left?right|class|dir<ltr?rtl|id|lang|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"dl[class|compact<compact|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
    //    +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
    //    +"|onmouseup|style|title],"
    //  +"dt[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
    //    +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"em/i[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"fieldset[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"font[class|color|dir<ltr?rtl|face|id|lang|size|style|title],"
    //  +"form[accept|accept-charset|action|class|dir<ltr?rtl|enctype|id|lang"
    //    +"|method<get?post|name|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
    //    +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onreset|onsubmit"
    //    +"|style|title|target],"
    //  +"frame[class|frameborder|id|longdesc|marginheight|marginwidth|name"
    //    +"|noresize<noresize|scrolling<auto?no?yes|src|style|title],"
    //  +"frameset[class|cols|id|onload|onunload|rows|style|title],"
    //  +"h1[align<center?justify?left?right|class|dir<ltr?rtl|id|lang|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"h2[align<center?justify?left?right|class|dir<ltr?rtl|id|lang|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"h3[align<center?justify?left?right|class|dir<ltr?rtl|id|lang|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"h4[align<center?justify?left?right|class|dir<ltr?rtl|id|lang|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"h5[align<center?justify?left?right|class|dir<ltr?rtl|id|lang|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"h6[align<center?justify?left?right|class|dir<ltr?rtl|id|lang|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"head[dir<ltr?rtl|lang|profile],"
    //  +"hr[align<center?left?right|class|dir<ltr?rtl|id|lang|noshade<noshade|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|size|style|title|width],"
    //  +"html[dir<ltr?rtl|lang|version],"
    //  +"iframe[align<bottom?left?middle?right?top|class|frameborder|height|id"
    //    +"|longdesc|marginheight|marginwidth|name|scrolling<auto?no?yes|src|style"
    //    +"|title|width],"
    //  +"img[align<bottom?left?middle?right?top|alt|border|class|dir<ltr?rtl|height"
    //    +"|hspace|id|ismap<ismap|lang|longdesc|name|onclick|ondblclick|onkeydown"
    //    +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
    //    +"|onmouseup|src|style|title|usemap|vspace|width],"
    //  +"input[accept|accesskey|align<bottom?left?middle?right?top|alt"
    //    +"|checked<checked|class|dir<ltr?rtl|disabled<disabled|id|ismap<ismap|lang"
    //    +"|maxlength|name|onblur|onclick|ondblclick|onfocus|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onselect"
    //    +"|readonly<readonly|size|src|style|tabindex|title"
    //    +"|type<button?checkbox?file?hidden?image?password?radio?reset?submit?text"
    //    +"|usemap|value],"
    //  +"ins[cite|class|datetime|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
    //    +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
    //    +"|onmouseup|style|title],"
    //  +"isindex[class|dir<ltr?rtl|id|lang|prompt|style|title],"
    //  +"kbd[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"label[accesskey|class|dir<ltr?rtl|for|id|lang|onblur|onclick|ondblclick"
    //    +"|onfocus|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout"
    //    +"|onmouseover|onmouseup|style|title],"
    //  +"legend[align<bottom?left?right?top|accesskey|class|dir<ltr?rtl|id|lang"
    //    +"|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"li[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
    //    +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title|type"
    //    +"|value],"
    //  +"link[charset|class|dir<ltr?rtl|href|hreflang|id|lang|media|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|rel|rev|style|title|target|type],"
    //  +"map[class|dir<ltr?rtl|id|lang|name|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"menu[class|compact<compact|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
    //    +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
    //    +"|onmouseup|style|title],"
    //  +"meta[content|dir<ltr?rtl|http-equiv|lang|name|scheme],"
    //  +"noframes[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"noscript[class|dir<ltr?rtl|id|lang|style|title],"
    //  +"object[align<bottom?left?middle?right?top|archive|border|class|classid"
    //    +"|codebase|codetype|data|declare|dir<ltr?rtl|height|hspace|id|lang|name"
    //    +"|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|standby|style|tabindex|title|type|usemap"
    //    +"|vspace|width],"
    //  +"ol[class|compact<compact|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
    //    +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
    //    +"|onmouseup|start|style|title|type],"
    //  +"optgroup[class|dir<ltr?rtl|disabled<disabled|id|label|lang|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"option[class|dir<ltr?rtl|disabled<disabled|id|label|lang|onclick|ondblclick"
    //    +"|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout"
    //    +"|onmouseover|onmouseup|selected<selected|style|title|value],"
    //  +"p[align<center?justify?left?right|class|dir<ltr?rtl|id|lang|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"param[id|name|type|value|valuetype<DATA?OBJECT?REF],"
    //  +"pre/listing/plaintext/xmp[align|class|dir<ltr?rtl|id|lang|onclick|ondblclick"
    //    +"|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout"
    //    +"|onmouseover|onmouseup|style|title|width],"
    //  +"q[cite|class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"s[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
    //    +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"samp[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"script[charset|defer|language|src|type],"
    //  +"select[class|dir<ltr?rtl|disabled<disabled|id|lang|multiple<multiple|name"
    //    +"|onblur|onchange|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup"
    //    +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|size|style"
    //    +"|tabindex|title],"
    //  +"small[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"span[align<center?justify?left?right|class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
    //    +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
    //    +"|onmouseup|style|title],"
    //  +"strike[class|class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
    //    +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
    //    +"|onmouseup|style|title],"
    //  +"strong/b[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"style[dir<ltr?rtl|lang|media|title|type],"
    //  +"sub[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"sup[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title],"
    //  +"table[align<center?left?right|bgcolor|border|cellpadding|cellspacing|class"
    //    +"|dir<ltr?rtl|frame|height|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|rules"
    //    +"|style|summary|title|width],"
    //  +"tbody[align<center?char?justify?left?right|char|class|charoff|dir<ltr?rtl|id"
    //    +"|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown"
    //    +"|onmousemove|onmouseout|onmouseover|onmouseup|style|title"
    //    +"|valign<baseline?bottom?middle?top],"
    //  +"td[abbr|align<center?char?justify?left?right|axis|bgcolor|char|charoff|class"
    //    +"|colspan|dir<ltr?rtl|headers|height|id|lang|nowrap<nowrap|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|rowspan|scope<col?colgroup?row?rowgroup"
    //    +"|style|title|valign<baseline?bottom?middle?top|width],"
    //  +"textarea[accesskey|class|cols|dir<ltr?rtl|disabled<disabled|id|lang|name"
    //    +"|onblur|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup"
    //    +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onselect"
    //    +"|readonly<readonly|rows|style|tabindex|title],"
    //  +"tfoot[align<center?char?justify?left?right|char|charoff|class|dir<ltr?rtl|id"
    //    +"|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown"
    //    +"|onmousemove|onmouseout|onmouseover|onmouseup|style|title"
    //    +"|valign<baseline?bottom?middle?top],"
    //  +"th[abbr|align<center?char?justify?left?right|axis|bgcolor|char|charoff|class"
    //    +"|colspan|dir<ltr?rtl|headers|height|id|lang|nowrap<nowrap|onclick"
    //    +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
    //    +"|onmouseout|onmouseover|onmouseup|rowspan|scope<col?colgroup?row?rowgroup"
    //    +"|style|title|valign<baseline?bottom?middle?top|width],"
    //  +"thead[align<center?char?justify?left?right|char|charoff|class|dir<ltr?rtl|id"
    //    +"|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown"
    //    +"|onmousemove|onmouseout|onmouseover|onmouseup|style|title"
    //    +"|valign<baseline?bottom?middle?top],"
    //  +"title[dir<ltr?rtl|lang],"
    //  +"tr[abbr|align<center?char?justify?left?right|bgcolor|char|charoff|class"
    //    +"|rowspan|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title|valign<baseline?bottom?middle?top],"
    //  +"tt[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
    //    +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"u[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
    //    +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],"
    //  +"ul[class|compact<compact|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
    //    +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
    //    +"|onmouseup|style|title|type],"
    //  +"var[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
    //    +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
    //    +"|title]"

  };
  for (var key in originalSettings) {
　　settings[key] = originalSettings[key];
  }
  tinyMCE.init(settings);
};
