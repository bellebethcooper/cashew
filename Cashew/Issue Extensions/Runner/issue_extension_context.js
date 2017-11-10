function _Cashew_makeObjectsReadOnly(o) {
    if (o instanceof Array) {
        for (var i =0; i < o.length; i++) {
            _Cashew_makeObjectsReadOnly(o[i]);
        }
    } else {
        for (var i in o) {
            Object.defineProperty(o, i, { value: o[i], writable: false });
            if (!!o[i] && typeof(o[i])=="object") {
                _Cashew_makeObjectsReadOnly(o[i]);
            }
        }
    }

}

function _Cashew_execute(issues) {
    _Cashew_makeObjectsReadOnly(issues)
    execute(issues)
}


var console = { log: function() { _consoleLog(arguments) } }

var MilestoneService = {
    milestonesForRepository: function(repository, completion) {
        _Cashew_JSMilestoneServiceMilestonesForRepository(repository, function(milestones, error) {
            if (milestones) { _Cashew_makeObjectsReadOnly(milestones) }
            completion(milestones, error)
        })
    }
}

var LabelService = {
    labelsForRepository: function(repository, completion) {
        _Cashew_JSLabelServiceLabelsForRepository(repository, function(labels, error) {
            if (labels) { _Cashew_makeObjectsReadOnly(labels) }
            completion(labels, error)
        })
    }
}

var OwnerService = {
    usersForRepository: function(repository, completion) {
        _Cashew_JSOwnerServiceUsersForRepository(repository, function(users, error) {
            if (users) { _Cashew_makeObjectsReadOnly(users) }
            completion(users, error)
        })
    }
}

var IssueService = {
    closeIssue: function(issue, completion) {
        _Cashew_JSIssueServiceCloseIssue(issue, function(issue, error) {
            if (issue) { _Cashew_makeObjectsReadOnly(issue) }
            completion(issue, error)
        })
    },

    openIssue: function(issue, completion) {
        _Cashew_JSIssueServiceOpenIssue(issue, function(issue, error) {
            if (issue) { _Cashew_makeObjectsReadOnly(issue) }
            completion(issue, error)
        })
    },

    assignMilestoneToIssue: function(issue, milestone, completion) {
        _Cashew_JSIssueServiceAssignMilestoneToIssue(issue, milestone, function(issue, error) {
            if (issue) { _Cashew_makeObjectsReadOnly(issue) }
            completion(issue, error)
        })
    },

    assignUserToIssue: function(issue, user, completion) {
        _Cashew_JSIssueServiceAssignUserToIssue(issue, user, function(issue, error) {
            if (issue) { _Cashew_makeObjectsReadOnly(issue) }
            completion(issue, error)
        })
    },

    assignLabelsToIssue: function(issue, labels, completion) {
        _Cashew_JSIssueServiceAssignLabelsToIssue(issue, labels, function(issue, error) {
            if (issue) { _Cashew_makeObjectsReadOnly(issue) }
            completion(issue, error)
        })
    },

    createIssueComment: function(issue, comment, completion) {
        _Cashew_JSIssueServiceCreateIssueComment(issue, comment, function(issue, error) {
            if (issue) { _Cashew_makeObjectsReadOnly(issue) }
            completion(issue, error)
        })
    },

    saveIssueTitle: function(issue, title, completion) {
        _Cashew_JSIssueServiceSaveIssueTitle(issue, title, function(issue, error) {
            if (issue) { _Cashew_makeObjectsReadOnly(issue) }
            completion(issue, error)
        })
    },

    saveIssueBody: function(issue, body, completion) {
        _Cashew_JSIssueServiceSaveIssueBody(issue, body, function(issue, error) {
            if (issue) { _Cashew_makeObjectsReadOnly(issue) }
            completion(issue, error)
        })
    }

}

var Pasteboard = { copyText: function(str) { _writeToPasteboard(str) } }
