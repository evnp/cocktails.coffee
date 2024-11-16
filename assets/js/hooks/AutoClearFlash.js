const AutoClearFlash = {
  // Clear Phoenix flash messages automatically after 5 seconds.
  mounted() {
    if (!["client-error", "server-error"].includes(this.el.id)) {
      // Hide flash element after 3 seconds, with animation:
      this.el.style.transition = "opacity 0.3s ease-in, transform 0.5s ease-in";
      this.el.style.opacity = 1;
      setTimeout(() => {
        this.el.style.opacity = 0;
        this.el.style.transform = "translateY(-100px)";
      }, 3_000);
      // Clear flash message from the LiveView channel connection 0.5s later:
      setTimeout(() => this.pushEvent("lv:clear-flash"), 3_500);
    }
  },
};

export default AutoClearFlash;
