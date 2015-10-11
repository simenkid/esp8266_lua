// Example from IBM Redbook

// Topic Manager - used by MessageFactory
var TopicManager = (function () {
    var _basePassengerTopic = 'pickmeup/passengers/';
    var _pasengerId = null; // will be set
    // ...

    var getPassengerLocationTopic = function () {
        return _basePassengerTopic + _pasengerId + '/location';
    }
    // ...

    return {
        getPassengerLocationTopic: getPassengerLocationTopic,
        // ...
    }
})();

// MessageFactory
var MessageFactory = (function () {
    // ...
    var getDriverLocationMessage = function (driverGeo) {
        return {
            topic: TopicManager.getDriverLocationTopic(),
            payload: JSON.stringify({
                lon: driverGeo.lon,
                lat: driverGeo.lat
            }),
            qos: 0,
            retained: true
        }
    }
    // ...

    return {
        getDriverLocationMessage: getDriverLocationMessage,
        // ...
    }
})();

// Subscription Factory
var SubscriptionFactory = (function () {
    // ...
    var getPassengerLocationSubscription = function () {
        var topic = TopicManager.getPassengerLocationTopic();
        return {
            topic: topic,
            qos: 0,
            onSuccess: function () {
                if (Util.TRACE) {
                    console.log("subscribed to " + topic);
                }
            }
        }
    };

    return {
        getPassengerLocationSubscription: getPassengerLocationSubscription,
        // ...
    }
})();

// MessageHandler

var MessageHandler = (function () {
    var processMessage = function (topic, payload) {
        // ...
        if (topic.match(TopicManager.getPassengerLocationTopic())) {
            _processPassenegerLocationMessage(topic, payload);
        }
        // ...
    };

    var _processPassenegerLocationMessage = function (topic, payload) {
        // dont process retained messages clearing the location data
        if (payload == '') { return; }

        var passengerId = topic.split('/')[2];
        var data = JSON.parse(payload);
        var lon = data.lon;
        vat lat = data.lat;

        window.app.updatePassengerLocation(passengerId, lon. lat);
    };

    // ... ohter specific handler functions

    return {
        processMessage: processMessage
    };
})();

// Messenger publish and subsribe
var Messenger = (function (global) {
    var TopicManager = (function () {
        // ...
    })();

    var MessageFactory = (function () {
        // ...
    })();

    var SubscriptionFactory = (function () {
        // ...
    })();

    var MessageHandler = (function () {
        // ...
    })();

    // ...

    var _client = new Messaging.Client(SERVER, PORT, CLIENT_ID);

    var publish = function (msgFactoryObj) {
        var topic = msgFactoryObj.topic;
        var payload = msgFactoryObj.payload;
        var qos = msgFactoryObj.qos;
        var retained = msgFactoryObj.retained;

        var msg = new Messaging.Message(payload);
        msg.destinationName = topic;
        msg.qos = qos;
        msg.retained = retained;
        _client.send(msg);
    };

    var subsribe = function (subFactoryObj) {
        var topic = subFactoryObj.topic;
        var qos = subFactoryObj.qos;
        var onSuccess = subFactoryObj.onSuccess;

        _client.subsribe(topic, {
            qos: qos,
            onSuccess: onSuccess
        });
    };

    // ...

    return {
        // ...
        publish: publish,
        subsribe: subsribe
    }
})(window);