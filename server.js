// ConnectedNES (Rachel Simone Weil, 2016)
// nobadmemories.com/connectednes


// Set up twitter and app credentials (See dev.twitter.com)
var Twit = require('twit');
var T = new Twit({
    consumer_key:         process.env.mytwitterconsumerkey, 
    consumer_secret:      process.env.mytwitterconsumersecret,
    access_token:         process.env.mytwitteraccesstokenkey,
    access_token_secret:  process.env.mytwitteraccesstokensecret
})


// Set up Particle Photon and credentials (See particle.io)
var Particle = require('particle-api-js');
var particle = new Particle();
particle.login({username: process.env.mysparkemail, password: process.env.mysparkpw});


// Check twitter streaming API for these words
var stream = T.stream('statuses/filter', { track: ['connectedNES','oscon'] })


// Parse incoming tweets
stream.on('tweet', function(json) {
    
    var text = json.text;
    //// Username associated with a tweet is printed to the NES on its own line and padded with spaces so the NES doesn't have to figure out line breaks. Each line contains 24 characters.
    var user = ("@" + json.user.screen_name + "                       ").slice(0,24);
    //// Date is reformatted to display more concisely.
    var month = json.created_at.slice(4,7);
    var day = json.created_at.slice(8,10);
    var hour = json.created_at.slice(11,13);
    var min = json.created_at.slice(14,16);
    //// This is a quick-and-dirty fix for Central Standard Time. It should someday be replaced with something more universal. Currently, this code will give an incorrect result if the day/month/year has just switched over. This can be fixed in the future by adding lookup tables or by using a date-parsing Javascript library. To be implemented at a later date.
    var ampm = 'A';
        hour = hour - 5;
        if (hour <= 0) {
            hour = hour + 12;
            ampm = 'P';
        }
        else if (hour > 12) {
            hour = hour - 12;
            ampm = 'P';
        }
        else {}
    //// Display shortened date on a single space-paddded line
    var fulldate = (month + ' ' + day + ' ' + hour + ':' + min + ampm + "                        ").slice(0,24);
    //// Split tweet text across six lines
    splitTweet(text);
    //// Print a preview of the tweet to the console
    console.log(user);
    console.log(line1);
    console.log(line2);
    console.log(line3);
    console.log(line4);
    console.log(line5);
    console.log(line6);
    console.log(fulldate);
    //// We'll send all eight lines, even if some of them are blank, to the NES. Clear lines will blank out whatever tiles were printed previously, and this way the NES doesn't have to parse anything.
    var fullpayload = user + line1 + line2 + line3 + line4 + line5 + line6 + fulldate;
    //// Stream data payload to Particle Photon
    var publishEventPr = particle.publishEvent({ name: 'tweet', data: fullpayload, auth: process.env.mysparktoken });
    publishEventPr.then(
        function(data) {
            if (data.ok) { console.log("Event published succesfully") }
        },
        function(err) {
            console.log("Failed to publish event: " + err)
        }
    );
    
});


// Print information to console for monitoring/debugging
stream.on('limit', function (limitMessage) {
  console.log("Limit message from twitter! " + limitMessage);
});
stream.on('disconnect', function (disconnectMessage) {
  console.log("Disconnected from twitter! " + disconnectMessage);
});
stream.on('reconnect', function (request, response, connectInterval) {
  console.log("Reconnecting to twitter... wait " + connectInterval)
});
stream.on('warning', function (warning) {
  console.log("Warning! Queue may be falling behind! " + warning);
});




function splitTweet(x){
    //// Clear out all lines from previous tweet.
    line1 = ' ';
    line2 = ' ';
    line3 = ' ';
    line4 = ' ';
    line5 = ' ';
    line6 = ' ';
    var tweetlines = [line1, line2, line3, line4, line5, line6];
    //// Replace emoji and unrecognized characters outside of basic ASCII with a '?'
    x = x.replace(/([\u007F-\uFF8FF])/g, '?');
    //// Figure out how to cleverly break a tweet into six lines with no more than 24 characters per line. Deals with edge cases like very long words or tweets that must be truncated.
    var tweetlength = x.length;
    if (tweetlength <= 24) {
        tweetlines[0] = x;
    }
    if (tweetlength > 24) {
        var words = x.split(' ');
        var wordcount = words.length;
        for (k = 0; k < words.length; k++) {
            if (words[k].length > 24) {
                words.splice(k, 0, words[k].slice(0,24));
                words.splice(k+1, 1, words[k+1].slice(24));
            }
        }
        var i = 0;
        line1 = words[i];
        for (j = 0; j < 6; j++) {
            if ((tweetlines[j] + ' ' + words[(i+1)]).length > 24) {
                tweetlines[j] = words[i+1];
                i++;
            }
            else {
                while ((tweetlines[j] + ' ' + words[(i+1)]).length <= 24 && typeof words[(i+1)] != "undefined") {
                    tweetlines[j] = tweetlines[j] + ' ' + words[(i+1)];
                    i++;
                }
            } 
        }
    }
        line1 = (tweetlines[0].trim() + "                        ").slice(0,24);
        line2 = (tweetlines[1].trim() + "                        ").slice(0,24);
        line3 = (tweetlines[2].trim() + "                        ").slice(0,24);
        line4 = (tweetlines[3].trim() + "                        ").slice(0,24);
        line5 = (tweetlines[4].trim() + "                        ").slice(0,24);
        line6 = (tweetlines[5].trim() + "                        ").slice(0,24);
}
