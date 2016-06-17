"use strict";

var webPage = require('webpage');
var page = webPage.create();
var url = 'http://dynamics.sandisk.com/Dynamics/main.aspx'

page.onConsoleMessage = function(msg) {
    console.log(msg);
}

page.viewportSize = {
    width: 1024,
    height: 768
};

//var logTime = function(start) {
//    var end = new Date().getTime();
//    var time = end - start;
//}

var faceOff = function() {
    page.evaluate(function() {
        $('#InlineDialog_Background').hide()
        $('#InlineDialog').hide()
        console.log('Say goodbye to the lady')
    })
}

var dropDown = function() {
    page.evaluate(function() {
        $('#TabTEST').click()
        console.log('Drop down the list')
    })
}

var openTCRRequest = function() {
    page.evaluate(function() {
        $('#zsd_tcrrequest').click()
        console.log('Click the TCR REQUEST')
    })
}

var getQueue = function(withinQueue) {
    if (withinQueue === null || typeof withinQueue !== 'boolean') {
        console.log('Need to input true if querying the Queue')
        phantom.exit()
    }
    return page.evaluate(function(wiQ) {
        var tcrArr = []
        var tcrRows = wiQ ?
            $('#contentIFrame0').contents().find("tr.ms-crm-List-Row[oid][otype]") :
            $('#contentIFrame1').contents().find("tr.ms-crm-List-Row[oid][otype]")

        console.log('Found ' + tcrRows.length + (wiQ ? ' in the Queue' : ' in the 1st page of TCR Request'))
        for (var i = 0; i < tcrRows.length; i++) {
            var otype = tcrRows[i].attributes['otype'].value
            var oid = tcrRows[i].attributes['oid'].value
            var uri = 'http://dynamics.sandisk.com/Dynamics/main.aspx?etc=' + encodeURIComponent(otype) +
                '&id=' + encodeURIComponent(oid) +
                '&newWindow=true&pagetype=entityrecord'
            tcrArr.push(uri)
        }

        return tcrArr
    }, withinQueue)
}

var postData = function(data) {
    var start = new Date().getTime();

    var server = 'http://localhost:8080';
    page.open(server, 'post', encodeURIComponent(data), function(status) {
        console.log('Post TCR urls')
        if (status !== 'success') {
            console.log('Unable to post!');
        } else {
            console.log(page.content);
        }
        phantom.exit();
    });
}

var searchTCR = function(tcrN) {
    if (tcrN === null || (typeof tcrN) !== 'string') {
        console.log('Need a string as TCR number for searching')
        phantom.exit();
    }

    page.evaluate(function(tn) {
        $('#contentIFrame1').contents().find('#crmGrid_findCriteria').val(tn)
        $('#contentIFrame1').contents().find('#crmGrid_findCriteriaImg').click()
    }, tcrN)
}

page.open(url, function(status) {
    if (status !== 'success') {
        console.log('Failed to load page')
        phantom.exit();
    }

    page.render('w.png');

    setTimeout(function() {

        faceOff()
        page.render('w2.png');

        dropDown()
        setTimeout(function() {
            page.render('w3.png');

            openTCRRequest()
            setTimeout(function() {

                //searchTCR( '*10861' )

                setTimeout(function() {
                    page.render('w4.png');

                    var urlArr = getQueue(true)
                    console.log(urlArr)
                    //postData(urlArr)

                    //phantom.exit()
                }, 2000)
            }, 2000)
        }, 2000)
    }, 2000)
})
