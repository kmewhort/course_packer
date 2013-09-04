/*
 *= require flexpaper.js
 */

function Preview(container){
    this.container = $(container);
}

Preview.prototype.load = function(swf_file){
    this.container.FlexPaperViewer(
        { config : {
            SwfFile : swf_file,
            // IMGFiles : "Paper.pdf_{page}.png",
            // JSONFile : "Paper.pdf.js",
            // PDFFile : "Paper.pdf",
            Scale : 0.6,
            ZoomTransition : "easeOut",
            ZoomTime : 0.5,
            ZoomInterval : 0.1,
            FitPageOnLoad : false,
            FitWidthOnLoad : false,
            FullScreenAsMaxWindow : true,
            ProgressiveLoading : true,
            MinZoomSize : 0.2,
            MaxZoomSize : 5,
            SearchMatchAll : false,
            InitViewMode : 'Portrait',

            ViewModeToolsVisible : true,
            ZoomToolsVisible : true,
            NavToolsVisible : true,
            CursorToolsVisible : true,
            SearchToolsVisible : true,

            localeChain : "en_US",

            jsDirectory : '/assets/foobar/' //flexpaper.js looks for FlexPaperViewer.swf in <jsDirectory>/../
        }});
}
