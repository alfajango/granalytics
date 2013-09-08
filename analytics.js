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
            keys = response.lookup_keys,
            series = [],
            dateStart = range[0]*1000,
            dateInterval = (range[1] - range[0])*1000,
            showLegend = false;

        for (var i = 0, ilen = response.results.length; i < ilen; i++) {
          var record = response.results[i];

          for (var k = 0, klen = keys.length; k < klen; k++) {
            var timeKey = keys[k],
                recordName = record.name,
                s = {
                  data: [],
                  pointInterval: dateInterval,
                  pointStart: dateStart
                };

            if (klen > 1) {
              var timeKeyArray = timeKey.split('.'),
                  index = timeKeyArray.indexOf('{{t}}');

              timeKeyArray.splice(index, 1);

              if (timeKeyArray.length) {
                // Don't know if recordName is defined or not,
                // and don't want a separator if it's undefined.
                recordName = recordName ? recordName + ' - ' : '';
                recordName += timeKeyArray.slice(-1)[0];
              }
            }
            s.name = recordName;
            if (s.name) {
              showLegend = true;
            }

            for (var t = 0, tlen = range.length; t < tlen; t++) {
              var x = range[t],
                  y = getKey(record, timeKey.replace('{{t}}', response.granularity + '.' + x)) || 0;
              s.data.push( y );
            }

            series.push(s);
          }
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

        if (!showLegend) {
          options.legend.enabled = false;
        }

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
