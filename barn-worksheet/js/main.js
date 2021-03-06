// Generated by CoffeeScript 1.10.0
var Main, Moment, React, ReactDOM, _, a, button, classFactory, div, form, h1, h2, hr, input, main, option, ref, ref1, section, select, span, table, tbody, td, tr, withKeys;

_ = require('underscore');

Moment = require('moment');

React = require('react');

ReactDOM = require('react-dom');

ref = require('./lib/ReactDOM'), tr = ref.tr, td = ref.td, table = ref.table, tbody = ref.tbody, a = ref.a, select = ref.select, option = ref.option, hr = ref.hr, section = ref.section, button = ref.button, div = ref.div, form = ref.form, h1 = ref.h1, h2 = ref.h2, input = ref.input, span = ref.span;

ref1 = require('./lib/ReactUtils'), classFactory = ref1.classFactory, withKeys = ref1.withKeys;

main = function() {
  return ReactDOM.render(Main({}), document.getElementById('content'));
};

Main = classFactory({
  displayName: 'Main',
  getInitialState: function() {
    var j, now, ref2, ref3, results;
    now = Moment();
    return {
      month: now.format('MMM'),
      year: now.year(),
      years: (function() {
        results = [];
        for (var j = ref2 = now.year(), ref3 = now.year() + 4; ref2 <= ref3 ? j <= ref3 : j >= ref3; ref2 <= ref3 ? j++ : j--){ results.push(j); }
        return results;
      }).apply(this)
    };
  },
  componentDidMount: function() {},
  setMonth: function(e) {
    return this.setState({
      month: e.target.value
    });
  },
  setYear: function(e) {
    return this.setState({
      year: e.target.value
    });
  },
  next: function(e) {
    return this.incrMonth(e, +1);
  },
  prev: function(e) {
    return this.incrMonth(e, -1);
  },
  curr: function() {
    return Moment(this.state.month + " " + this.state.year, 'MMM YYYY');
  },
  incrMonth: function(e, incr) {
    var curr;
    e.preventDefault();
    curr = this.curr();
    curr.add(incr, 'months');
    return this.setState({
      month: curr.format('MMM'),
      year: curr.year()
    });
  },
  getFullMonth: function() {
    var next;
    next = this.curr();
    next.add(1, 'months');
    return {
      curr: this.curr().format('MMMM'),
      next: next.format('MMMM')
    };
  },
  getMonths: function() {
    return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  },
  render: function() {
    var month, year;
    return div({}, div({
      "class": 'nav'
    }, a({
      href: '#',
      onClick: this.prev
    }, '<<'), ' ', select({
      value: this.state.month,
      onChange: this.setMonth
    }, (function() {
      var j, len, ref2, results;
      ref2 = this.getMonths();
      results = [];
      for (j = 0, len = ref2.length; j < len; j++) {
        month = ref2[j];
        results.push(option({
          key: month,
          value: month
        }, month));
      }
      return results;
    }).call(this)), ' ', select({
      value: this.state.year,
      onChange: this.setYear
    }, (function() {
      var j, len, ref2, results;
      ref2 = this.state.years;
      results = [];
      for (j = 0, len = ref2.length; j < len; j++) {
        year = ref2[j];
        results.push(option({
          key: year,
          value: year
        }, year));
      }
      return results;
    }).call(this)), ' ', a({
      href: '#',
      onClick: this.next
    }, '>>')), table({}, tbody({}, this._rows())));
  },
  _head1: function() {
    return tr({
      "class": 'head1',
      key: '99'
    }, td({
      colSpan: '4'
    }, this.state.year), td({
      "class": 'months'
    }, this.getFullMonth().curr, ' to ', this.getFullMonth().next));
  },
  _rows: function() {
    var i, j, m, rows;
    rows = [];
    rows.push(this._head1());
    rows.push(tr({
      "class": 'head2',
      key: '98'
    }, td({}), td({}), td('AM'), td('PM'), td('NOTES')));
    m = this.curr();
    m.date(16);
    while (true) {
      rows.push(tr({
        key: m.date()
      }, td({
        style: {
          border: '1px solid black'
        }
      }, m.format('dd')), td(m.date()), td({}), td({}), td({
        style: {
          width: '80%'
        }
      })));
      m.add(1, 'days');
      if (m.date() === 16) {
        break;
      }
    }
    rows.push(tr({
      key: 200,
      "class": 'divider'
    }, td({})));
    for (i = j = 1; j <= 8; i = ++j) {
      rows.push(tr({
        key: i + 100,
        "class": 'notes'
      }, td({
        colSpan: 2
      }, i === 1 ? 'Notes:' : ''), td({
        colSpan: 3,
        "class": 'underline'
      }, ' ')));
    }
    return rows;
  }
});

main();
