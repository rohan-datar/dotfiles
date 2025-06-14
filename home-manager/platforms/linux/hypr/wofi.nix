{...}: {
  programs.wofi = {
    enable = true;
    style = ''
      /* Window */
      window {
        margin: 0px;
        padding: 10px;
        border: 2px solid;
        border-radius: 8px;
      }

      /* Inner Box */
      #inner-box {
        margin: 5px;
        padding: 10px;
        border: none;
      }

      /* Outer Box */
      #outer-box {
        margin: 5px;
        padding: 10px;
        border: none;
      }

      /* Scroll */
      #scroll {
        margin: 0px;
        padding: 10px;
        border: none;
      }

      /* Input */
      #input {
        margin: 5px 20px;
        padding: 10px;
        border: none;
        border-radius: 0.1em;
        color: @text;
      }

      #input image {
          border: none;
          color: @red;
      }


      /* Text */
      #text {
        margin: 5px;
        border: none;
      }


      #entry arrow {
        border: none;
      }

      /* Selected Entry */
      #entry:selected {
        border: 0.11em solid;
      }
    '';
  };
}
