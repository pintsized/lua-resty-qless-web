<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>{{ application_name }}{{  (title and #title > 0) and (" | " ..title) or "" }}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="Dan Lecocq">

    <link href="{* uri_prefix .. "/css/bootstrap.css" *}" rel="stylesheet">
    <link href="{* uri_prefix .. "/css/bootstrap-responsive.css" *}" rel="stylesheet">
    <link href="{* uri_prefix .. "/css/docs.css" *}" rel="stylesheet">
    <link href="{* uri_prefix .. "/css/jquery.noty.css" *}" rel="stylesheet">
    <link href="{* uri_prefix .. "/css/noty_theme_twitter.css" *}" rel="stylesheet">
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js" type="text/javascript"></script>

    <style type="text/css">
    body {
      padding-top: 60px;
    }

    .btn-group span {
      /* This is ugly. Anyone want to change it? */
      border-color: #e6e6e6 #e6e6e6 #bfbfbf;
      border-color: rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.25);
      border: 1px solid #cccccc;
      border-bottom-color: #b3b3b3;
      background-color: #f5f5f5;
      font-size: 13px;
      line-height: 18px;
      padding: 4px 10px 4px;
    }

   .btn-group input, .btn-group span {
      position: relative;
      float: left;
      margin-left: -1px;
      -webkit-border-radius: 0;
      -moz-border-radius: 0;
      border-radius: 0;
      margin-bottom: 0px;
    }

    .btn-group input:first-child, .btn-group span:first-child {
      margin-left: 0;
      -webkit-border-top-left-radius: 4px;
      -moz-border-radius-topleft: 4px;
      border-top-left-radius: 4px;
      -webkit-border-bottom-left-radius: 4px;
      -moz-border-radius-bottomleft: 4px;
      border-bottom-left-radius: 4px;
    }

    .large-text {
      font-size:18px;
    }

    .queue-column {
      min-width:300px;
    }

    </style>

    <script type="text/javascript">
    /* This is a helper method to display an alert at the top of the page,
     * in a vein similar to that of Ruby's flash */
    var flash = function(message, t, duration) {
      var noty_id = noty({
        text   : '<strong>' + message + '</strong>',
        layout : 'top',
        type   : t || 'error',
        theme  : 'noty_theme_twitter',
        timeout: duration || 1500});
    }

    /* This just sets a few options that we use */
    var _ajax = function(obj) {
      $.ajax({
        url: obj.url,
        type: 'POST',
        dataType: 'json',
        data: JSON.stringify(obj.data),
        processData: false,
        success: obj.success || function() {},
        error: obj.error || function() {}
      });
    }

    /* This is a helper method to move a job into a queue, and then it will
     * flash a message to that effect on the page */
    var move = function(jid, queue, cb) {
      _ajax({
        url: '{* uri_prefix .. "/move" *}',
        data: {id:jid, queue:queue},
        success: function() { flash('Moved ' + jid + ' to ' + queue, 'success', 1500); cb(jid, queue); },
        erorr:   function() { flash('Failed to move ' + jid + ' to ' + queue); }
      });
    }

    /* Helper function for retrying a job */
    var retry = function(jid, cb) {
      _ajax({
        url: '{* uri_prefix .. "/retry" *}',
        data: {id:jid},
        success: function() { flash('Retrying ' + jid, 'success', 1500); if (cb) { cb(jid, 'retry'); } },
        erorr:   function() { flash('Failed to retry ' + jid); }
      });
    }

    /* This is a helper method to cancel a job */
    var cancel = function(jid, cb) {
      _ajax({
        url: '{* uri_prefix .. "/cancel" *}',
        data: [jid],
        success: function() { flash('Canceled ' + jid, null, 1500); if (cb) { cb(jid, 'cancel'); } },
        error:   function() { flash('Failed to cancel ' + jid); }
      });
    }

    /* This is a helper method to untrack a job */
    var untrack = function(jid, cb) {
      _ajax({
        url: '{* uri_prefix .. "/untrack" *}',
        data: [jid],
        success: function() { flash('Stopped tracking ' + jid, 'success', 1500); if (cb) { cb(jid, 'untrack'); }  },
        error:   function() { flash('Failed to track ' + jid); }
      });
    }

    /* This is a helper to start tracking a job, with tags */
    var track = function(jid, tags, cb) {
      _ajax({
        url: '{* uri_prefix .. "/track" *}',
        data: {id:jid, tags:(tags || [])},
        success: function() { flash('Now tracking ' + jid, 'success', 1500); if (cb) { cb(jid, 'track'); }  },
        error:   function() { flash('Failed to track ' + jid); }
      });
    }

    /* This is a helper to retry all jobs of a certain failure type */
    var retryall = function(type, cb) {
      _ajax({
        url: '{* uri_prefix .. "/retryall" *}',
        data: {type: type},
        success: function(response) {
          flash('Retrying failures of type ' + type, 'success', 1500);
          if (cb) {
            for (var i in response) {
              cb(response[i].id);
            }
          }
        },
        error:   function() { flash('Failed to retry failures of type ' + type); }
      });
    }

    /* This is a helper to cancel all jobs of a certain failure type */
    var cancelall = function(type, cb) {
      _ajax({
        url: '{* uri_prefix .. "/cancelall" *}',
        data: {type: type},
        success: function(response) {
          flash('Canceling failures of type ' + type, 'success', 1500);
          if (cb) {
            for (var i in response) {
              cb(response[i].id);
            }
          }
        },
        error:   function() { flash('Failed to cancel failures of type ' + type); }
      });
    }

    /* This is a helper to remove job dependencies */
    var undepend = function(jid, dependency, cb) {
      _ajax({
        url: '{* uri_prefix .. "/undepend" *}',
        data: {id:jid, dependency:dependency},
        success: function() { flash(jid + ' no longer depends on ' + dependency, 'success', 1500); if (cb) { cb(jid, 'undepend'); }  },
        error:   function() { flash('Failed to remove ' + jid + '\'s dependency on ' + dependency); }
      });
    }

    /* Helper function to fade out a particular element id */
    var fade = function(jid, type) {
      if (type != 'untrack' && type != 'track') {
        $('#job-' + jid).slideUp();
      }
    }

    /* Helper function to make a button ask for confirmation
     * after being pressed once. Accepts the confirmation text,
     * and the function to execute after it has been run */
    var confirmation = function(button, html, action, delay) {
      var obj      = $(button);
      var original = obj.html();
      var timeout  = setTimeout(function() {
        obj.html(original).unbind('click').click(function() {
          confirmation(button, html, action, delay);
        });
      }, delay || 3000);
      obj.removeAttr('onclick').html(html).unbind('click').click(function() {
        clearTimeout(timeout);
        obj.html(original).unbind('click').click(function() {
          confirmation(button, html, action, delay);
        });
        action();
      });
    }

    /* Helper function for adding a tag to a job */
    var tag = function(jid, tag) {
      var data  = {};
      data[jid] = [tag];
      // The button group of the 'add tag' bit
      var group =
      _ajax({
        url: '{* uri_prefix .. "/tag" *}',
        data: data,
        success : function() {
          var div  = $('<div>').attr('class', 'btn-group').attr('style', 'float:left');
          var span = $('<span>').attr('class', 'tag').text(tag);
          var btn  = $('<button>').attr('class', 'btn').click(function() {
            untag(jid, tag);
          });
          btn.append($('<i>').attr('class', 'icon-remove'));
          div.append(span).append(btn);
          $('#job-' + jid).find('.add-tag').val(null).parent().before(div);
        }, error: function() {
          flash('Failed to tag ' + jid + ' with ' + tag);
        }
      });
    }

    /* Helper function for untagging a job */
    var untag = function(jid, tag) {
      var data  = {};
      data[jid] = [tag];
      // The button group of the 'add tag' bit
      var group =
      _ajax({
        url: '{* uri_prefix .. "/untag" *}',
        data: data,
        success : function() {
          $("#job-" + jid).find('.tag').filter(function() {
            return $(this).text() === tag;
          }).parent().remove();
        }, error: function() {
          flash('Failed to untag ' + jid + ' with ' + tag);
        }
      });
    }

    /* Helper function for changing a job's priority */
    var priority = function(jid, priority) {
      var p     = parseInt(priority);
      var input = $('#job-' + jid).find('.priority');
      if (p != null) {
        input.attr('disabled', true);
        var data = {};
        data[jid] = priority;
        _ajax({
          url: '{* uri_prefix .. "/priority" *}',
          data: data,
          success : function(data) {
            if (data[jid] != 'failed' && data[jid] != null) {
              input.attr('disabled', false).attr('placeholder', 'Pri ' + priority).val(null).blur();
            } else {
              flash('Couldn\'t reprioritize ' + jid);
              input.val(null).blur();
            }
          }, error: function() {
            flash('Couldn\'t reprioritize ' + jid);
            input.val(null).blur();
          }
        });
      } else {
        // Reset it to its original value, and print an error
        flash('Cannot derive integer from "' + priority + '"');
        input.val(null).blur();
      }
    }

    var pause = function(queue) {
      _ajax({
        url: '{* uri_prefix .. "/pause" *}',
        data: {
          'queue': queue
        }, success: function(data) {
          var button = $('#' + queue + '-pause');
          button.attr('title', 'Unpause').attr(
            'data-original-title', 'Unpause');
          button.addClass('btn-success').removeClass('btn-warning');
          button.children().addClass('icon-play').removeClass('icon-pause');
          button.attr('onclick', 'unpause("' + queue + '")');
        }, error: function() {
          flash('Couldn\'t pause queue ' + queue);
        }
      })
    }

    var unpause = function(queue) {
      _ajax({
        url: '{* uri_prefix .. "/unpause" *}',
        data: {
          'queue': queue
        }, success: function(data) {
          var button = $('#' + queue + '-pause');
          button.attr('title', 'Pause').attr(
            'data-original-title', 'Pause');
          button.addClass('btn-warning').removeClass('btn-success');
          button.children().addClass('icon-pause').removeClass('icon-play');
          button.attr('onclick', 'pause("' + queue + '")');
        }, error: function() {
          flash('Couldn\'t unpause queue ' + queue);
        }
      })
    }

    var timeout = function(jid) {
      _ajax({
        url: '{* uri_prefix .. "/timeout" *}',
        data: {
          'jid': jid
        }, success: function(data) {
          flash('Job timed out', 'success');
        }, error: function(data) {
          flash('Failed to time out job: ' + data);
          console.log(data);
        }
      })
    }

    $(document).ready(function() {
      $('button').tooltip({delay:200});
    });
    </script>
    <!-- Le HTML5 shim, for IE6-8 support of HTML5 elements -->
    <!--[if lt IE 9]>
    <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
  </head>

  <body>
    <div class="navbar navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container">
          <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </a>
          <a class="brand" href="{* uri_prefix .. "/" *}">{{ application_name }}</a>
          <div class="nav-collapse">
            <ul class="nav nav-bar">
            {% for _,tab in pairs(tabs) do %}
              <li><a href='{* uri_prefix .. tab.path *}'>{{ tab.name }}</a></li>
            {% end %}
            </ul>
            <ul class="nav nav-bar pull-right">
              <li>
                <form class="navbar-search" action="{* uri_prefix .. "/tag" *}">
                  <input id="tag-search" type="text" class="search-query" placeholder="Search by Tag" data-provide="typeahead" name="tag"/>
                </form>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>

      <div class="container">
      {*view*}
      <!-- <footer class="footer">
        <p>Powered by <a href="http://github.com/seomoz/qless">qless</a> </p>
      </footer> -->
      </div> <!-- /container -->

    <!-- Le javascript
    ================================================== -->
    <script src="{* uri_prefix .. "/js/bootstrap.min.js" *}"></script>
    <script src="{* uri_prefix .. "/js/bootstrap-tab.js" *}"></script>
    <script src="{* uri_prefix .. "/js/bootstrap-alert.js" *}"></script>
    <script src="{* uri_prefix .. "/js/bootstrap-tooltip.js" *}"></script>
    <script src="{* uri_prefix .. "/js/bootstrap-scrollspy.js" *}"></script>
    <script src="{* uri_prefix .. "/js/bootstrap-typeahead.js" *}"></script>

    <!-- Noty! This is such a wonderful-looking library, and /exactly/ what I wanted. Thank you so much! -->
    <script src="{* uri_prefix .. "/js/jquery.noty.js" *}"></script>
    <!--
    <script src="../assets/js/bootstrap-transition.js"></script>
    <script src="../assets/js/bootstrap-modal.js"></script>
    <script src="../assets/js/bootstrap-dropdown.js"></script>
    <script src="../assets/js/bootstrap-popover.js"></script>
    <script src="../assets/js/bootstrap-button.js"></script>
    <script src="../assets/js/bootstrap-collapse.js"></script>
    <script src="../assets/js/bootstrap-carousel.js"></script>
    -->
  </body>
</html>
