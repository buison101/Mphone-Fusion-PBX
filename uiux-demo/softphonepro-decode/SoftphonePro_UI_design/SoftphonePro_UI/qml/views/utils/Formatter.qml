import QtQuick 2.15
import Flux 1.0

Item {
    id: root

    function formatDuration(msec) {
        if (msec < 0) {
            msec = 0;
        }

        var durationSeconds = Math.round(msec / 1000);

        var hours = Math.floor(durationSeconds / (60 * 60));

        durationSeconds = durationSeconds - hours * (60 * 60);

        var minutes = Math.floor(durationSeconds / (60));

        durationSeconds = durationSeconds - minutes * 60;

        var seconds = durationSeconds;

        if (hours < 10) {
            hours = "0" + hours;
        }

        if (minutes < 10) {
            minutes = "0" + minutes;
        }

        if (seconds < 10) {
            seconds = "0" + seconds;
        }

        var duration = minutes + ":" + seconds;

        if (hours != "00") {
            duration =  hours + ":"  + duration;
        }

        return duration;
    }

    function formatStatus(status) {
        switch(Number(status)) {
        case SipCall.Connecting:
        case SipCall.Calling:
            return qsTrId("sip_call_status_calling") + Translator.translate;

        case SipCall.Answered:
            return qsTrId("sip_call_status_answered") + Translator.translate;

        case SipCall.Finished:
            return qsTrId("sip_call_status_finished") + Translator.translate;

        case SipCall.Busy:
            return qsTrId("sip_call_status_busy") + Translator.translate;

        case SipCall.Declined:
            return qsTrId("sip_call_status_declined") + Translator.translate;

        case SipCall.OnHold:
            return qsTrId("sip_call_status_onhold") + Translator.translate;

        default:
           return qsTrId("sip_call_status_unknown") + Translator.translate;
        }
    }
}
