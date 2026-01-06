if command -v agent >/dev/null 2>&1; then
    # Base aliases
    alias ag='agent'
    alias aga='agent --mode ask'
    alias agp='agent --mode plan'
    alias age='agent'

    # Model selection aliases (default mode)
    alias agc='agent --model composer-1'
    alias ags='agent --model sonnet-4.5'
    alias ago='agent --model opus-4.5'

    # Ask mode with model selection
    alias agac='agent --mode ask --model composer-1'
    alias agas='agent --mode ask --model sonnet-4.5'
    alias agao='agent --mode ask --model opus-4.5'

    # Plan mode with model selection
    alias agpc='agent --mode plan --model composer-1'
    alias agps='agent --mode plan --model sonnet-4.5'
    alias agpo='agent --mode plan --model opus-4.5'

    # Edit mode (default) with model selection
    alias agec='agent --model composer-1'
    alias ages='agent --model sonnet-4.5'
    alias ageo='agent --model opus-4.5'
fi
