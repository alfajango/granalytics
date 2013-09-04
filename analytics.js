var getKey = function(o, k) {
  var a = k.split('.');
  while (a.length) {
    var n = a.shift();
    if (n in o) {
      o = o[n];
    } else {
      return;
    }
  }
  return o;
};

var loadAssignmentEvents = function() {
  $.getJSON('/analytics/assignment_events.json', function(response) {
    var range = response.range,
        series = [],
        dateStart = range[0]*1000,
        dateInterval = (range[1] - range[0])*1000,
        keys = response.keys;

    for (var i = 0, ilen = response.data.length; i < ilen; i++) {
      var record = response.data[i],
          s = {
            name: record.name,
            data: [],
            pointInterval: dateInterval,
            pointStart: dateStart
          };

      for (var t = 0, tlen = range.length; t < tlen; t++) {
        var x = range[t],
            key = getKey(record, response.key),
            y = key[x] ? key[x] : 0;
        s.data.push( y );
      }

      series.push(s);
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
