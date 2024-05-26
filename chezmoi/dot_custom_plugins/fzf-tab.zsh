# fzf-tab - https://github.com/Aloxaf/fzf-tab

FZF_DIR="$HOME/custom_plugins/fzf-tab"

if command -v git > /dev/null 2>&1; then
    if command -v fzf > /dev/null 2>&1; then
        if [ ! -d "$FZF_DIR" ]; then
          echo "\033[32mCloning Aloxaf/fzf-tab\033[m"
          git clone git@github.com:Aloxaf/fzf-tab.git "$FZF_DIR"
        else
          echo "\033[33mfzf-tab already installed, pulling latest changes\033[m"
          git -C "$FZF_DIR" pull
          echo "\033[32mPulled Aloxaf/fzf-tab\033[m"
        fi
    else
      echo "\033[33mFzf is not installed, fzf is a requirement for fzf-tab\033[m"
    fi
else
  echo "\033[33mGit is not installed, skipping installation of fzf-tab\033[m"
fi
