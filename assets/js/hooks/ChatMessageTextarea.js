const ChatMessageTextarea = {
  mounted() {
    this.el.addEventListener("keydown", (ev) => {
      if (ev.key === "Enter" && !ev.shiftKey) {
        const form = this.el.closest("form");
        const options = { bubbles: true, cancelable: true };

        this.el.dispatchEvent(new Event("change", options));
        form.dispatchEvent(new Event("submit", options));
      }
    });
  },
};

export default ChatMessageTextarea;
