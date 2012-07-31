Object.defineProperty(Date.prototype, "toShortTimeString", {
    enumerable: false,
    value: function() {
      var hours   = this.getHours();
      var minutes = this.getMinutes();
      var seconds = this.getSeconds();

      if (hours   < 10) {hours   = "0"+hours;}
      if (minutes < 10) {minutes = "0"+minutes;}
      if (seconds < 10) {seconds = "0"+seconds;}
      var time    = hours+':'+minutes+':'+seconds;
      return time;
    }
});
