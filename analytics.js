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

var loadAnalytics = function() {
  $('[data-chart]').each( function() {
    var $this = $(this),
        chartType = $this.data('chart');

    $.getJSON($this.data('url'), function(response) {

      if (chartType === 'timeseries') {
        var range = response.range,
            series = [],
            dateStart = range[0]*1000,
            dateInterval = (range[1] - range[0])*1000;

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

        options = {
          title: {
            text: $this.data('title'),
                      x: -20 //center
          },
          subtitle: {
            text: $this.data('subtitle'),
                    x: -20
          },
          xAxis: {
            type: 'datetime',
            dateTimeLabelFormats: { // don't display the dummy year
              minute: '%H:%M'
            }
          },
          yAxis: {
            min: 0,
            title: {
              text: $this.data('y-axis-label')
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
        };

        if ($this.data('y-axis-max')) {
          options.yAxis.max = parseFloat($this.data('y-axis-max'));
        }

        $this.highcharts(options);
      };
    });

  });
};

$(document).delegate('#refresh', 'click', function(e) {
  loadAnalytics();
  e.preventDefault();
});

$(function () {
  Highcharts.setOptions({
    global: {
      useUTC: false
    }
  });
  loadAnalytics();
});
