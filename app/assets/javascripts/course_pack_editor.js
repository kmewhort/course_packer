/*
 *= require jquery.ui.droppable
 *= require jquery.iframe-transport
 *= require jquery.fileupload
 *= require jquery.autosize
 *= require jquery.ui.slider
 *= require jquery.ui.sortable
 */

function CoursePackEditor(container){
    this.container = $(container);

    // add new article action
    var editor = this;
    this.container.find('#add-article').click(function(){ editor.newArticle(); });

    // file upload widgets
    $('.file-upload').each(function(){ editor.ajaxifyFileUpload(this); });

    // autosize text areas
    $('textarea').autosize();

    // page range sliders
    $( ".page-range").each(function(){
        editor.addPageRangeSlider(this);
    });

    // sortability
    this.container.find('tbody').sortable({
        axis: 'y',
        tolerance: 'pointer',
        update: function(){ editor.reassignWeights(); }
    });
}

// add a row for a new empty article
CoursePackEditor.prototype.newArticle = function(){
    // copy the last article
    var lastArticle = this.container.find('tr.article:last');
    var newArticle = lastArticle.clone().insertAfter(lastArticle);

    // reset the inputs and increment the indexes in the name attributes
    var index = null;
    newArticle.find('input').each(function(){
        // increment the weight, clear all other values
        if($(this).hasClass('weight')){
            $(this).val(parseInt($(this).val()) + 1);
        }
        else{
            $(this).val('');
        }

        var name = $(this).attr('name');
        if(name){
            if(index == null)
              index = parseInt(/(\d+)/.exec(name)[1]) + 1;
            $(this).attr('name', name.replace(/\d+/, index));
        }
    });

    // remove the file thumbnail
    newArticle.find('.file-thumb').empty();

    // remove the page slider
    newArticle.find('.page-range-slider').empty().attr('class', 'page-range-slider');
    newArticle.find('.page-range').addClass('hidden');

    // assign a temporary id
    var temp_id = this.uniqueTemporaryId();
    $('<input>').attr('id',temp_id)
        .attr('name', 'course_pack[articles_attributes][' + index + '][temp_id]')
        .attr('type', 'hidden')
        .val(temp_id)
        .insertAfter(newArticle);
    newArticle.data('article-id',temp_id);

    this.ajaxifyFileUpload(newArticle.find('.file-upload'));
    newArticle.find('textarea').autosize();
}

CoursePackEditor.prototype.ajaxifyFileUpload = function(element){
    var widget = this;
    var progressBar = $(element).find('.progress');
    var progressStatus = $(element).find('progress-bar');

    var coursePackId = $(element).data('coursepack-id');
    var uploadUrl = "/course_packs/" + coursePackId;
    var uploadType = 'PUT';

    $(element).find('input[type=file]').fileupload({
        url: uploadUrl,
        type: uploadType,
        dataType: 'json',
        send: function(e, data){
            $(element).find('.alert').remove();
            progressBar.removeClass('hidden');
        },
        progress: function (e, data) {
            var progress = parseInt(data.loaded / data.total * 100, 10);
            progressStatus.css('width', progress + '%');
        },
        done: function (e, data) {
            // replace any temporary IDs with the permanent ones
            widget.substituteTemporaryIds(data.result);

            var articleId = $(element).closest('.article').data('article-id');
            $.each(data.result.articles, function(){
                if((this._id == articleId) || (this.temp_id == articleId)){
                    // show a thumbnail of the first page
                    $(element).parent().find('.file-thumb').empty()
                        .append($('<img>').attr('src',this.file.thumbnail.url));

                    // enable page slider
                    widget.addPageRangeSlider($(element).parent().find('.page-range'));
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

CoursePackEditor.prototype.addPageRangeSlider = function(element){
    var container = $(element);
    var numPages = container.data('num-pages');

    if(numPages){
        var pageStartInput = container.find('input.page_start');
        var pageEndInput = container.find('input.page_end');

        container.removeClass('hidden');

        container.find('.page-range-slider').slider({
            range: true,
            min: 1,
            max: numPages,
            values: [ (pageStartInput.val() != "" ? pageStartInput.val() : 1),
                      (pageEndInput.val() != "" ? pageEndInput.val() : numPages)],
            slide: function( event, ui ) {
                pageStartInput.val(ui.values[0]);
                pageEndInput.val(ui.values[1]);
            }
        });
    }
}

// reassign weight values based on the current order of the articles in the dom
CoursePackEditor.prototype.reassignWeights = function(){
    var weight = 0;
    this.container.find('input.weight').each(function(){
      $(this).val(weight++);
    });
}

// replace temporary IDs assigned to articles with any permanent IDs returned back by the server;
CoursePackEditor.prototype.substituteTemporaryIds = function(course_pack_data){
    if(course_pack_data.articles){
        $.each(course_pack_data.articles, function(){
            if(this._id && this.temp_id)
            {
                var id_input = $('#' + this.temp_id);
                id_input.attr('name', id_input.attr('name').replace('temp_', ''))
                        .val(this._id);

                $('.article').each(function(){
                    if($(this).data('article-id') == this.temp_id)
                      $(this).data('article-id', this.id);
                });
            }
        });
    }
}

CoursePackEditor.prototype.uniqueTemporaryId = function(element){
    if(typeof(this.temp_id_iterator) == 'undefined')
      this.temp_id_iterator = 0;
    return 'course-pack-editor-tid-' + (++this.temp_id_iterator);
}