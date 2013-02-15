module.exports = function() {
    var scheduler = {
        domain: require('domain').create(),

        initialize: function() {
            this.domain.on("error", function(error) {
                console.error(error.stack);
            })
        },

        schedule: function(callback, millis) {
            var errorHandlingCallBack = this.domain.bind(callback);
            setInterval(errorHandlingCallBack, millis);
            errorHandlingCallBack();
        }
    };
    scheduler.initialize();
    return scheduler;
}