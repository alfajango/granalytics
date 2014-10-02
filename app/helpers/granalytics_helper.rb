module GranalyticsHelper
  def granalytics_chart_inputs(chart_id, default_range=nil, default_granularity=nil)
    content_tag :div, :class => 'analytics-inputs' do
      concat(content_tag(:div, class: 'small-12 large-4 columns') do
        concat label_tag("#{chart_id}-range", 'Range: ')
        concat select_tag('range', options_for_select(Granalytics.configuration.default_range_options_for_select, default_range), :data => {:for_chart => chart_id, :select => 'range'}, :id => "#{chart_id}-range" )
      end)
      concat(content_tag(:div, class: 'small-12 large-4 columns') do
        concat label_tag("#{chart_id}-granularity", 'Granularity: ')
        concat select_tag('granularity', options_for_select(Granalytics.configuration.default_granularity_options_for_select, default_granularity), :data => {:for_chart => chart_id, :select => 'granularity'}, :id => "#{chart_id}-granularity" )
      end)
      concat link_to "Refresh", "#", :data => {:refresh_chart => chart_id}, :class => "button tiny radius"
    end
  end
end
