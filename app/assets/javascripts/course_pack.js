/*
 *= require best_in_place
 */

$(document).ready(function(){
    /*
        Edit
     */
    $('#course-pack_editor').each(function(){
        var course_pack_id = $(this).data('course-pack-id');

        // initialize best in place
        $(".best_in_place").best_in_place();

        // load course pack preview
        var preview = new Preview($('#preview')[0]);
        $.ajax({
            url: '/course_packs/' + course_pack_id + '/prepare_preview',
            method: 'PUT',
            success: function(data){
                preview.load('/course_packs/' + course_pack_id + '/preview.pdf');
            }
        });

        // load course pack editor
        var editor = new CoursePackEditor($('.course-pack-editor')[0], preview);

        // ajaxify form submit (updating the preview after the submit completes)
        $('#course-pack_editor input[type=submit]').click(function(e){
            var btn = $(this);
            var form = btn.closest('form');
            e.preventDefault();

            // disable the button to prevent repeat clicks
            btn.attr('disabled', 'disabled');

            // submit the form manually;
            $.ajax({
                url: form.attr('action'),
                method: 'POST',
                data: form.serialize(),
                dataType: 'json',
                success: function(data){

                    // load the preview
                    $.ajax({
                        url: '/course_packs/' + course_pack_id + '/prepare_preview',
                        method: 'PUT',
                        success: function(data){
                            preview.load('/course_packs/' + course_pack_id + '/preview.pdf');
                        },
                        complete: function(){
                            btn.removeAttr('disabled');
                        },
                        error: function(){
                            preview.clear();
                        }
                    });
                },
                error: function(){
                    btn.removeAttr('disabled');
                }
            });
            return false;
        });
    });

    /*
     * View
     */
    $('#show-course-pack').each(function(){
        var course_pack_id = $(this).data('course-pack-id');

        // load course pack pdf preview
        var preview = new Preview($('#preview')[0]);
        $.ajax({
            url: '/course_packs/' + course_pack_id + '/prepare_preview',
            method: 'PUT',
            success: function(data){
                preview.load('/course_packs/' + course_pack_id + '/preview.pdf');
            }
        });
    });
});
