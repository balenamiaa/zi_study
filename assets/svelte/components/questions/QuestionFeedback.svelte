<script>
    let { 
        isCorrect, 
        userResponse, 
        correctResponse = null,
        class: userClass = ""
    } = $props();
</script>

<div class="mt-4 p-4 rounded-lg {isCorrect 
    ? 'bg-success/10 border border-success/20' 
    : 'bg-error/10 border border-error/20'} {userClass}">
    <div class="flex items-start gap-2">
        {#if isCorrect}
            <svg class="w-5 h-5 text-success mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            <div>
                <div class="font-medium text-success">Correct!</div>
                <div class="text-sm text-base-content/70 mt-1">
                    <slot name="user-response">
                        You selected: {userResponse}
                    </slot>
                </div>
            </div>
        {:else}
            <svg class="w-5 h-5 text-error mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
            <div>
                <div class="font-medium text-error">Incorrect</div>
                <div class="text-sm text-base-content/70 mt-1">
                    <slot name="user-response">
                        You selected: {userResponse}
                    </slot>
                </div>
                {#if correctResponse}
                    <div class="text-sm text-success mt-1">
                        <slot name="correct-response">
                            Correct answer: {correctResponse}
                        </slot>
                    </div>
                {/if}
            </div>
        {/if}
    </div>
</div> 