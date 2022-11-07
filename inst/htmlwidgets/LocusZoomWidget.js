HTMLWidgets.widget({

  name: 'LocusZoomWidget',

  type: 'output',

  factory: function(el, width, height) {
    try{
      var a = LocusZoom.Adapters.get('CustomAssociation');
    } catch (Error) {
      // TODO: define shared variables for this instance
      const AssociationLZ = LocusZoom.Adapters.get('AssociationLZ');
      class CustomAssociation extends AssociationLZ {
        _getURL(request_options) {
          // Every adapter receives the info from plot.state, plus any additional request options calculated/added in the function `_buildRequestOptions`
          // The inputs to the function can be used to influence what query is constructed. Eg, since the current view region is stored in `plot.state`:
          const {chr, start, end} = request_options;
          // Fetch the region of interest from a hypothetical REST API that uses query parameters to define the region query, for a given study URL such as `data.example/gwas/<id>/?chr=_&start=_&end=_`
          return `${this._url}/?chr=${encodeURIComponent(chr)}&start=${encodeURIComponent(start)}&end=${encodeURIComponent(end)}`
            }
        };
        LocusZoom.Adapters.add('CustomAssociation', CustomAssociation);
    }

    try {
      var a = LocusZoom.Adapters.get('CustomStatic');
    } catch(Error){
      const BaseUMAdapter = LocusZoom.Adapters.get('BaseUMAdapter');
      class CustomStatic extends BaseUMAdapter {
        constructor(config = {}){
          super(config)
        }
        _performRequest(options){
            return Promise.resolve(this._config.data);
        }
      }


      LocusZoom.Adapters.add('CustomStatic', CustomStatic);
    }
    return {

      renderValue: function(x) {

        // Create custom adapters
        // TODO: code to render the widget, e.g.
        const mybuild = x.build // 'GRCh37' or 'GRCh38'
        const apiBase = 'https://portaldev.sph.umich.edu/api/v1/';
        var plttype;
        if (x.bed == null){
          plttype = 'standard_association';
        } else {
          plttype = 'interval_association';
        }
        console.log(x.bed);
        // const apiloc = 'data/';
        // const apiloc = window.location.origin + window.location.pathname.substr(0, window.location.pathname.lastIndexOf("/") + 1) + "data/";
        // var apiloc = window.location.origin + window.location.pathname.substr(0, window.location.pathname.lastIndexOf("/") + 1) + x.json;

        var data_sources = new LocusZoom.DataSources()
          // .add('assoc', ['AssociationLZ', {url: apiBase + 'statistic/single/', source: 45, id_field: 'variant' }])
          // .add('assoc', ['AssociationLZ', {url: apiloc + 'chip_b38.epacts_chr_16_2088708-2135898.json', params: {source: null}}])
          // .add('assoc', ['AssociationLZ', {url: apiloc + 'assoc_10_114550452-115067678.json', params: {source: null}}])
          // .add('assoc', ['AssociationLZ', {url: apiloc, source: 1, id_field: 'variant'}])
          // .add('assoc', ['CustomAssociation', {url: apiloc}])
          // .add('assoc', ['CustomStatic', {data: myblob, source:null, build: mybuild}])
          // .add("assoc", ["AssociationLZ", {url: apiBase + "statistic/single/", source: 45 }])
          // .add('intervals', ["IntervalLZ", { url: apiBase + "annotation/intervals/results/", source: 19 }])
          .add('ld', ['LDServer', { url: 'https://portaldev.sph.umich.edu/ld/', source: '1000G', population: 'ALL', build: mybuild }])
          .add('recomb', ['RecombLZ', { url: apiBase + 'annotation/recomb/results/', build: mybuild }])
          .add('gene', ['GeneLZ', { url: apiBase + 'annotation/genes/', build: mybuild }])
          .add('constraint', ['GeneConstraintLZ', { url: 'https://gnomad.broadinstitute.org/api/', build: mybuild }]);

        if (x.url){
          const apiloc = x.url;
          data_sources.add('assoc', ['CustomAssociation', {url: apiloc, build: mybuild}]);
          if (plttype == 'interval_association'){
            data_sources.add('intervals', ["IntervalLZ", { url: apiBase + "annotation/intervals/results/", source: 19 }]);
          }
        } else {
          data_sources.add('assoc', ['CustomStatic', {data: x.blob, source:null, build: mybuild}]);
          if (plttype == 'interval_association'){
            data_sources.add('intervals', ['CustomStatic', {data: x.bed, source:null, build: mybuild}]);
          }
          console.log("BLOBS");
        }

        var layout = LocusZoom.Layouts.get(
          'plot',
          plttype,
          {
            // state: { genome_build: mybuild, chr: 16, start: 2088708, end: 2135898},
            state: { genome_build: mybuild, chr: x.chr, start: x.bpstart, end: x.bpend},
            /* panels: [
              LocusZoom.Layouts.get('panel', 'association',
              {
                title: {text: x.title},
                height: height / 2
              }
            ),
              LocusZoom.Layouts.get('panel', 'genes', {height: height/2}),
            ],
            min_region_scale: 20000,
            max_region_scale: 1000000
            */
          }
        );


        // Modify the tooltips for PheWAS result data layer points to contain more data. The fields in this sample
        //   tooltip are specific to the LZ-Portal API, and are not guaranteed to be in other PheWAS datasources.

        LocusZoom.Layouts.mutate_attrs(layout, '$..data_layers[?(@.tag === "association")].tooltip', LocusZoom.Layouts.get('tooltip', 'standard_association_with_label'));
        LocusZoom.Layouts.mutate_attrs(layout, '$..data_layers[?(@.tag === "association")].label', {
          text: '{{assoc:variant}}',
          spacing: 12,
          lines: {
            style: { 'stroke-width': '2px', 'stroke': '#333333', 'stroke-dasharray': '2px 2px' }
          },
          filters: [
            { field: 'lz_show_label', operator: '=', value: true }
          ],
          style: {
            'font-weight': 'bold',
          }
        });


        /* LocusZoom.Layouts.mutate_attrs(layout, '$..data_layers[?(@.tag === "association")].tooltip.html', [
            "<strong>Variant:</strong> {{assoc:variant|htmlescape}}<br>",
            "<strong>P-Value Category:</strong> {{assoc:pvalue|scinotation|htmlescape}}<br>",
            "<strong>LogP-value:</strong> {{phewas:log_pvalue|logtoscinotation|htmlescape}}"
            //"{{#if assoc:beta|is_numeric}}<br><strong>&beta;:</strong> {{assoc:beta|scinotation|htmlescape}}{{/if}}",
            //"{{#if assoc:se|is_numeric}}<br><strong>SE (&beta;):</strong> {{assoc:se|scinotation|htmlescape}}{{/if}}"
            ].join("")); */

        /*
        const layout = LocusZoom.Layouts.get(
          'plot',
          'standard_association',
          { state: { genome_build: mybuild, chr: 10, start: 114550452, end: 115067678} }
        );
        */

        /*
        const layout = LocusZoom.Layouts.get(
          'plot',
          'standard_association',
          { state: { genome_build: mybuild, chr: 16, start: 2088708, end: 2135898} }
        );
        */

        var plot = LocusZoom.populate(el, data_sources, layout);
        plot.layout.panels.forEach(function(panel){
            plot.panels[panel.id].addBasicLoader();
        });

        // window.plot

      },

      rsize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
