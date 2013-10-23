/*
 *= require jquery.ui.droppable
 *= require jquery.iframe-transport
 *= require jquery.fileupload
 *= require jquery.autosize
 *= require jquery.ui.slider
 *= require jquery.ui.sortable
 */

function CoursePackEditor(container){
    var widget = this;
    this.container = $(container);

    // add new article action
    var editor = this;
    this.container.find('#add-article').click(function(){ editor.newArticle(); });

    // add new chapter action
    this.container.find('#add-chapter').click(function(){ editor.newChapter(); });

    // file upload widgets
    this.container.find('.file-upload').each(function(){ editor.ajaxifyFileUpload(this); });

    // autosize text areas
    this.container.find('textarea').autosize();

    // page range sliders
    this.container.find( ".page-range").each(function(){
        editor.addPageRangeSlider(this, null);
    });

    // delete buttons
    this.container.find('.delete-article').click( function(){ widget.deleteContent(this); } );

    // depth buttons
    this.container.find('.depth-change').each(function(){
        editor.addDepthAdjustors(this);
    });

    // initial depth padding
    this.addDepthPadding();

    // sortability
    this.container.find('tbody').sortable({
        axis: 'y',
        tolerance: 'pointer',
        update: function(){ editor.reassignWeights(); }
    });
}

// add a row for a new empty article
CoursePackEditor.prototype.newArticle = function(){
    var widget = this;
    var lastTableRow = this.container.find('tr:last');

    // build the html from the micro-template
    var html = document.getElementById('article-template').innerHTML;
    var newArticle = $(html).find('tr').insertAfter(lastTableRow);

    // increment the weight input
    var lastWeight = parseInt(lastTableRow.find('input.weight').val());
    newArticle.find('input.weight').val(lastWeight+1);

    // assign an index (in the name attributes)
    var max_index = 0;
    this.container.find('tr').each(function(){
      var index = widget.rowIndex(this);
      if(index > max_index)
        max_index = index;
    });
    newArticle.find('input, textarea').each(function(){
        var name = $(this).attr('name');
        if(name){
          $(this).attr('name', name.replace(/\d+/, max_index+1));
        }
    });
    newArticle.data('row-index', max_index+1);

    // assign a unique id
    var id = this.uniqueId();
    $('<input>').attr('id',id)
        .attr('name', 'course_pack[contents_attributes][' + (max_index+1) + '][_id]')
        .attr('type', 'hidden')
        .val(id)
        .insertAfter(newArticle);
    newArticle.data('content-id',id);
    newArticle.find('.license-chooser').attr('id', id);

    this.ajaxifyFileUpload(newArticle.find('.file-upload'));
    newArticle.find('textarea').autosize();
    newArticle.find('.delete-article').click( function(){ widget.deleteContent(this); } );

    this.addDepthPadding();

    // initialize license chooser
    new LicenseChooser(newArticle.find('.license-chooser')[0]);
}

// add a row for a new chapter
CoursePackEditor.prototype.newChapter = function(){
    var widget = this;
    var lastTableRow = this.container.find('tr:last');

    // build the html from the micro-template
    var html = document.getElementById('chapter-seperator-template').innerHTML;
    var newChapter = $(html).find('tr').insertAfter(lastTableRow);

    // increment the weight input
    var lastWeight = parseInt(lastTableRow.find('input.weight').val());
    newChapter.find('input.weight').val(lastWeight+1);

    // assign an index (in the name attributes)
    var max_index = 0;
    this.container.find('tr').each(function(){
        var index = widget.rowIndex(this);
        if(index > max_index)
            max_index = index;
    });
    newChapter.find('input,textarea').each(function(){
        var name = $(this).attr('name');
        if(name){
            $(this).attr('name', name.replace(/\d+/, max_index+1));
        }
    });
    newChapter.data('row-index', max_index+1);

    // assign a unique id
    var id = this.uniqueId();
    $('<input>').attr('id',id)
        .attr('name', 'course_pack[contents_attributes][' + (max_index+1) + '][_id]')
        .attr('type', 'hidden')
        .val(id)
        .insertAfter(newChapter);
    newChapter.data('content-id',id);

    // depth adjustors
    this.addDepthAdjustors(newChapter.find('.depth-change'));

    newChapter.find('textarea').autosize();
    newChapter.find('.delete-article').click( function(){ widget.deleteContent(this); } );

    this.addDepthPadding();
}

CoursePackEditor.prototype.ajaxifyFileUpload = function(element){
    var widget = this;
    var progressBar = $(element).find('.progress');
    var progressStatus = $(element).find('.progress-bar');
    var progressStage = $(element).find('.progress-stage');

    var coursePackId = $(element).data('coursepack-id');
    var uploadUrl = "/course_packs/" + coursePackId;
    var uploadType = 'PUT';

    $(element).find('input[type=file]').fileupload({
        url: uploadUrl,
        type: uploadType,
        dataType: 'json',
        progressTimeEvents: 25,
        send: function(e, data){
            $(element).find('.alert').remove();
            progressStatus.css('width', '0');
            progressStage.text('Uploading...');
            progressBar.removeClass('hidden');
        },
        progress: function (e, data) {
            var progress = data.loaded / data.total;
            progressStatus.css('width', parseInt(progress*60) + '%'); // leave ~40% of the bar for processing

            // we won't get the final chunk until after processing, so switch status message after 90% complete
            if(progress > 0.90){
                progressStage.text('Processing...');
            }
        },
        done: function (e, data) {
            progressStatus.css('width', '100%');

            var contentId = $(element).closest('.content').data('content-id');
            $.each(data.result.contents, function(){
                if(this._id == contentId){
                    // show a thumbnail of the first page
                    $(element).parent().find('.file-thumb').empty()
                        .append($('<img>').attr('src',this.file.first_page.url));

                    // enable page slider
                    widget.addPageRangeSlider($(element).parent().find('.page-range'), this.num_pages);
                }
            });
        },
        fail: function(e, data) {
            var errMsg = $('<div>').addClass('alert alert-warning')
                .append($('<strong>').text('Error uploading file:'));
            var errList = $('<ul>').appendTo(errMsg);
            $.each($.parseJSON(data.jqXHR.responseText), function(){
                $('<li>').text(this).appendTo(errList);
            });
            errMsg.insertBefore(progressBar);
        },
        always: function(e, data) {
            progressBar.addClass('hidden');
        }
    });
}

CoursePackEditor.prototype.addPageRangeSlider = function(element, numPages){
    var container = $(element);
    if(!numPages)
      numPages = container.data('num-pages');

    if(numPages){
        var pageStartInput = container.find('input.page_start');
        var pageEndInput = container.find('input.page_end');
        var startValues = [ (pageStartInput.val() != "" ? pageStartInput.val() : 1),
            (pageEndInput.val() != "" ? pageEndInput.val() : numPages)];

        container.removeClass('hidden');

        container.find('.page-range-slider').slider({
            range: true,
            min: 1,
            max: numPages,
            values: startValues,
            slide: function(event, ui) {
                var sliderHandles = container.find('.ui-slider-handle');
                sliderHandles.eq(0).text(ui.values[0]);
                sliderHandles.eq(1).text(ui.values[1]);
            },
            change: function(event, ui){
                pageStartInput.val(ui.values[0]);
                pageEndInput.val(ui.values[1]);
            },
            create: function(obj){
                // show values right on the slider handles
                var sliderHandles = $(obj.target).find('.ui-slider-handle');
                sliderHandles.eq(0).addClass('page-start-display').text(startValues[0]);
                sliderHandles.eq(1).addClass('page-end-display').text(startValues[1]);
            }
        });
    }
}

// depth +/- action for the left/right icons on chapters
CoursePackEditor.prototype.addDepthAdjustors = function(container){
    var widget = this;
    $(container).find('.depth-left').click(function(){
        var input = $(this).closest('.chapter_seperator').find('.depth');
        var depth = parseInt(input.val());
        if(depth > 1)
          input.val(depth-1);

        widget.addDepthPadding();
    });
    $(container).find('.depth-right').click(function(){
        var input = $(this).closest('.chapter_seperator').find('.depth');
        var depth = parseInt(input.val());
        input.val(depth+1);

        widget.addDepthPadding();
    });
}

// reassign weight values based on the current order of the articles in the dom
CoursePackEditor.prototype.reassignWeights = function(){
    var weight = 0;
    this.container.find('input.weight').each(function(){
      $(this).val(weight++);
    });

    // reassign depth padding
    this.addDepthPadding();
}

// pad out articles/chapter rows based on the chapter depths
CoursePackEditor.prototype.addDepthPadding = function(){
    // find the max depth we'll go to
    var maxDepth = 0;
    this.container.find('.chapter_seperator input.depth').each(function(){
        var val = parseInt($(this).val());
        if(val > maxDepth){
           maxDepth = val;
        }
    });

    // pad out the articles
    var curDepth = 0;
    var withinChapter = false;
    this.container.find('tr').each(function(){
        var row = $(this);
        var isChapter = row.hasClass('chapter_seperator');
        if(isChapter){
          curDepth = parseInt(row.find('input.depth').val());
          withinChapter = true;
        }

        // set the required number of pads
        var requiredPads = isChapter ? curDepth-1 : curDepth;
        var curPads = row.find('td.pad').length;
        while(curPads > requiredPads){
          row.children('td.pad').first().remove();
          curPads--;
        }
        while(curPads < requiredPads){
            row.prepend($('<td>').addClass('pad'));
            curPads++;
        }

        // make the data column span across any unused columns
        row.find('td.data').attr('colspan', maxDepth-requiredPads+2);
    });
}

CoursePackEditor.prototype.deleteContent = function(delete_button){
    var content = $(delete_button).closest('.content');
    var is_article = content.hasClass('article');

    // confirm deletion
    var title = content.find('.title input').val();
    var confirm_text = null;
    if(title)
      confirm_text = 'Delete "' + title + '"?';
    else{
      if(is_article)
        confirm_text = 'Delete article?';
      else
        confirm_text = 'Delete chapter heading?';
    }
    if(!confirm(confirm_text))
      return;

    // hide the article
    content.attr('class', 'content deleted').css('display', 'none');

    // mark the content for deletion
    var index = this.rowIndex(content);
    var delete_marker = $('<input>').attr('type', 'hidden').attr('value', '1')
        .attr('name', 'course_pack[contents_attributes][' + index + '][_destroy]');
    content.find('td.data').empty().append(delete_marker);

    // if there will be no articles left, add a blank one
    if(is_article && (this.container.find('.article').length == 0)){
        this.newArticle();
    }

    this.addDepthPadding();
}

CoursePackEditor.prototype.rowIndex = function(row){
    // check if the index is set in the row data
    var index = $(row).data('row-index');

    // otherwise, parse it out of the title attribute
    if(typeof(index) == 'undefined'){
      var name = $(row).find('.title input').attr('name');
      index = /(\d+)/.exec(name)[1];
      $(row).data('row-index', index);
    }
    return parseInt(index);
}


/* generate random unique id */
CoursePackEditor.prototype.uniqueId = function(element){
    var uid = "";
    for(i = 0; i < 32; i++)
        uid += (Math.random()*16|0).toString(16);
    return uid;
}