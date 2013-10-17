var $selects;

//------------------------------------------------------------
// Utility functions
//------------------------------------------------------------

// Access nested values in a hash by passing a string,
// where nested keys are denoted by a period.
// E.g.
//     var myObj = {hi: {there: {whats: 'up'}}};
//     getKey(myObj, 'hi.there.whats'); //=> 'up'
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

// Replace mustache-style string variables in text with corresponding property in response object
// E.g.
//     response = {name: "you"};
//     subWithResponse("hi {{ name }}", response); //=> "hi you"
var subWithResponse = function(text, response) {
  return text && text.replace(/{{\s*([\w\.]+)\s*}}/g, function (match, capture) { return response[capture];});
};

//------------------------------------------------------------
// Build HighCharts options
//------------------------------------------------------------

var defaultChartOptions = {
  chart: {},
  title: {
    x: -20 //center
  },
  subtitle: {
    x: -20
  },
  xAxis: {
    type: 'datetime',
    dateTimeLabelFormats: { // don't display the year
      minute: '%H:%M'
    }
  },
  yAxis: {
    min: 0,
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
  plotOptions: {
    series: {
      events: {

        // Allow filtering shown series in chart
        legendItemClick: function(event) {
          var selected = this.index,
          allSeries = this.chart.series,
          state = this.toggleState || 'visible',
          othersAction;

          if (state === 'visible') {
            othersAction = 'hide';
            this.toggleState = 'solo';
          } else {
            othersAction = 'show';
            this.toggleState = 'visible';
          }

          // Hold shift, ctrl, or cmd to toggle just the clicked series
          if (event.browserEvent.metaKey || event.browserEvent.shiftKey || event.browserEvent.ctrlKey) {
            if (state === 'solo') {
              allSeries[selected].hide();
            } else {
              allSeries[selected].show();
            }

            // Otherwise, toggle between showing only the clicked series or all series
          } else {
            var i = 0,
            len = allSeries.length;

            // No idea why highcharts takes so long to loop through and hide/show series,
            // so for now, we need to use setTimeout to show the user something is happening
            // and not lock up the UI.
            function loopSeries() {
              if (selected === i) {
                allSeries[selected].show();
              } else {
                allSeries[i][othersAction]();
                delete allSeries[i]['toggle'];
              }

              i++;

              if (i < len) {
                setTimeout(loopSeries, 0.5);
              }
            }

            loopSeries();
          }

          return false;
        }
      }
    }
  }
};

var defaultTableOptions = {
  features: {
    search: false,
    perPageSelect: false,
    pushState: false
  },
  dataset: {
  }
};

var TimeLineOptions = function($el, response) {
  // Normally, this would be handle with prototypal inheritence:
  // E.g. ChartOptions.prototype = defaultChartOptions
  // But Highcharts won't recognize the properties in the prototype
  for (key in defaultChartOptions) {
    if (defaultChartOptions.hasOwnProperty(key)) {
      this[key] = $.extend(true, {}, defaultChartOptions[key]);
    }
  }
  this.title.text = subWithResponse($el.data('title'), response);
  this.subtitle.text = subWithResponse($el.data('subtitle'), response);
  this.yAxis.title = subWithResponse($el.data('y-axis-label'), response);

  this.series = timeLineSeries(response);

  // Only display legend when more than one series is present
  // and there are series labels to show.
  var showLegend = this.series.length > 1 && this.series.some( function(el) {
    return typeof(el.name != 'undefined');
  });
  this.legend.enabled = showLegend;

  if (this.series.length == 1) {
    this.chart.type = 'area';
  }

  if ($el.data('y-axis-max')) {
    this.yAxis.max = parseFloat($el.data('y-axis-max'));
  }
};

var TimeSummaryOptions = function($el, response) {
  // Normally, this would be handle with prototypal inheritence:
  // E.g. ChartOptions.prototype = defaultChartOptions
  // But Highcharts won't recognize the properties in the prototype
  for (key in defaultTableOptions) {
    if (defaultTableOptions.hasOwnProperty(key)) {
      this[key] = $.extend(true, {}, defaultTableOptions[key]);
    }
  }
  this.dataset.records = timeSummarySeries(response);
};

//------------------------------------------------------------
// AnalyticsData
// (create normalized data object from API responses)
//------------------------------------------------------------

var AnalyticsData = function(response) {
  this.range = response.range;
  this.keys = response.lookup_keys;
  this.dateStart = this.range[0]*1000;
  this.dateInterval = (this.range[1] - this.range[0])*1000;
  this.results = response.results;
  this.granularity = response.granularity;
};

// Builds time series collection matching format:
// series = [
//   {
//     name: 'blah',
//     pointInterval: 24 * 3600 * 1000,
//     pointStart: Date.UTC(2013, 8, 02),
//     data: [
//       50, 75, 64, 32
//     ]
//   }
// ]
//
// See: http://jsfiddle.net/gh/get/jquery/1.9.1/highslide-software/highcharts.com/tree/master/samples/highcharts/demo/line-time-series/

var timeLineSeries = function(response) {
  var data = new AnalyticsData(response),
      series = [];

  // Loop through results
  for (var i = 0, ilen = data.results.length; i < ilen; i++) {
    var record = data.results[i];

    // Loop through keys for each record (events, count, total, etc.)
    for (var k = 0, klen = data.keys.length; k < klen; k++) {
      var timeKey = data.keys[k],
          recordName = record.name,
          s = {
            data: [],
            pointInterval: data.dateInterval,
            pointStart: data.dateStart
          };

      // If record contains multiple aggregate keys, add key to series label
      if (klen > 1) {
        var timeKeyArray = timeKey.split('.'),
            index = timeKeyArray.indexOf('{{t}}');

        // But don't count the different timestamps as multiple keys
        timeKeyArray.splice(index, 1);

        if (timeKeyArray.length) {
          // Don't know if recordName is defined or not,
          // and don't want a separator if it's undefined.
          recordName = recordName ? recordName + ' - ' : '';
          recordName += timeKeyArray.slice(-1)[0];
        }
      }
      s.name = recordName;

      // Build the array of plot values
      for (var t = 0, tlen = data.range.length; t < tlen; t++) {
        var x = data.range[t],
            y = getKey(record, timeKey.replace('{{t}}', data.granularity + '.' + x)) || 0;
        s.data.push( y );
      }

      series.push(s);
    }
  }
  return series;
};

// Builds summary series for time data in format:
// series = [
//   {
//     name: 'blah',
//     total: 432
//   }
// ]

var timeSummarySeries = function(response) {
  var data = new AnalyticsData(response),
      series = [];

  // Loop through results
  for (var i = 0, ilen = data.results.length; i < ilen; i++) {
    var record = data.results[i],
        s = {
          name: record.name || 'Total',
        };

    // Loop through keys for each record (events, count, total, etc.)
    for (var k = 0, klen = data.keys.length; k < klen; k++) {
      var timeKey = data.keys[k],
          propertyName = 'total';

      // Set series properties from key names
      var timeKeyArray = timeKey.split('.'),
          index = timeKeyArray.indexOf('{{t}}');

      // But don't count the timestamp as part of the name
      timeKeyArray.splice(index, 1);

      if (timeKeyArray.length) {
        propertyName = timeKeyArray.slice(-1)[0];
      }
      s[propertyName] = 0;

      // Build total of all values in range
      for (var t = 0, tlen = data.range.length; t < tlen; t++) {
        var x = data.range[t],
            y = getKey(record, timeKey.replace('{{t}}', data.granularity + '.' + x)) || 0;
        s[propertyName] += y;
      }
    }

    if (s.total && s.count) {
      s.average = Math.round( s.total*10000 / s.count, 2 )/100;
    }
    series.push(s);
  }
  console.log(series);
  return series;
};

// Request analytics data for this chart element via ajax and bind callbacks
window.refreshAnalytics = function() {
  var $this = $(this),
      chartType = $this.data('chart'),
      $thisSelects = $selects.filter('[data-for-chart="' + this.id + '"]'),
      $granularity = $thisSelects.filter('[data-select="granularity"]'),
      $range = $thisSelects.filter('[data-select="range"]'),
      requestOptions = {},
      urlData = $this.data('url-data'),
      $refresh = $('[data-refresh-chart="' + this.id + '"]');

  if ($granularity.length) {
    requestOptions.granularity = $granularity.val();
  }
  if ($range.length) {
    requestOptions.range = $range.val();
  }

  if (urlData) {
    if (typeof urlData !== 'string') {
      urlData = $.param(urlData);
    }
    requestOptions = [$.param(requestOptions), urlData].join('&');
  }

  $.ajax({
    dataType: "json",
    url: $this.data('url'),
    data: requestOptions,
    beforeSend: function() {
      $refresh.html('Loading...').removeClass('btn-success').addClass('analytics-loading');
    },
    complete: function() {
      $refresh.html('Refresh').removeClass('analytics-loading');
    },
    success: function(response) {
      if (chartType === 'timeseries') {
        $this.highcharts( new TimeLineOptions($this, response) );
      } else if (chartType === 'timeseries-table') {
        if ($this.data('dynatable')) {
          $this.siblings('.dynatable-pagination-links,.dynatable-record-count').remove();
          $this.data('dynatable').sortsHeaders.removeAll();
          $this.removeData('dynatable');
        }
        $this.find('tbody').html('');
        $this.dynatable( new TimeSummaryOptions($this, response) );
      }
      $refresh.html('Refresh').removeClass('analytics-loading');
    }
  });
}

// Loop through [data-chart] elements and call refreshAnalytics function for each
var loadAnalytics = function() {
  $('[data-chart]').each( function() {
    var delayLoad = this.getAttribute('data-delay-load');
    if (!delayLoad && delayLoad !== "") {
      refreshAnalytics.call(this);
    }
  });
};

// Bind handlers for refresh buttons for each chart
$(document)
  .delegate('[data-refresh-chart]', 'click', function(e) {
    var chart = $(this).data('refresh-chart');
    refreshAnalytics.call( document.getElementById(chart) );
    e.preventDefault();
  })
  .delegate('[data-for-chart]', 'change', function() {
    var chart = $(this).data('for-chart');
    $('[data-refresh-chart="' + chart + '"]').addClass('btn-success');
  });

$(function () {
  // Show charts in browser's timezone instead of UTC as they are stored
  Highcharts.setOptions({
    global: {
      useUTC: false
    }
  });
  $selects = $('[data-for-chart]');
  loadAnalytics();
});
