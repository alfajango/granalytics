var loadAssignmentEvents = function() {
  $.getJSON('/analytics/assignment_events.json', function(response) {
    var range = response.range,
        series = [],
        dateStart = range[0]*1000,
        dateInterval = (range[1] - range[0])*1000;

    for (var a = 0, alen = response.data.length; a < alen; a++) {
      var assignment = response.data[a],
          assignmentId = assignment.assignment_id,
          assignmentName = response.assignments[assignmentId];
      for (var n = 0, nlen = response.events.length; n < nlen; n++) {
        var event = response.events[n],
            s = {
              name: assignmentName + '-' + event,
              data: [],
              pointInterval: dateInterval,
              pointStart: dateStart
            };
        for (var i = 0, len = range.length; i < len; i++) {
          var x = range[i],
              y = assignment.events[event].minutely[x] ? assignment.events[event].minutely[x] : 0;
          s.data.push( y );
        }
        series.push(s);
      }
    }

    $('#events-chart').highcharts({
      title: {
        text: 'Assignment Events',
                  x: -20 //center
      },
      subtitle: {
        text: 'per minute',
                x: -20
      },
      xAxis: {
        type: 'datetime',
        dateTimeLabelFormats: { // don't display the dummy year
          minute: '%H:%M'
        }
      },
      yAxis: {
        title: {
          text: 'Number of events'
        },
        plotLines: [{
          value: 0,
              width: 1,
              color: '#808080'
        }]
      },
      legend: {
        layout: 'vertical',
        align: 'right',
        verticalAlign: 'middle',
        borderWidth: 0
      },
      series: series
    });
  });
};

$(document).delegate('#refresh', 'click', function(e) {
  loadAssignmentEvents();
  e.preventDefault();
});

$(function () {
  Highcharts.setOptions({
    global: {
      useUTC: false
    }
  });
  loadAssignmentEvents();
});
