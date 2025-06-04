<script>
    import MarkdownContent from "../MarkdownContent.svelte";

    let {
        questionNumber,
        difficulty,
        retentionAid,
        hasExplanation = false,
        isAnswered = false,
        showExplanation = $bindable(false),
        onclearAnswer,
        class: userClass = "",
        children,
    } = $props();

    function toggleExplanation() {
        showExplanation = !showExplanation;
        const popover = document.getElementById(
            `toolbar-popover-${questionNumber}`,
        );
        popover?.hidePopover();
    }

    function clearAnswer() {
        if (onclearAnswer) {
            onclearAnswer();
        }
        const popover = document.getElementById(
            `toolbar-popover-${questionNumber}`,
        );
        popover?.hidePopover();
    }
</script>

<div class="flex items-center justify-between mb-4 {userClass}">
    <div class="flex items-center gap-3">
        <!-- Question Number -->
        <div
            class="w-8 h-8 bg-primary text-primary-content rounded-full flex items-center justify-center text-sm font-bold"
        >
            {questionNumber}
        </div>

        <div class="flex items-center justify-center gap-2">
            <!-- Difficulty Badge -->
            {#if difficulty}
                <div
                    class="tooltip tooltip-top flex items-center justify-center"
                    data-tip="Difficulty"
                >
                    <span
                        class="badge badge-secondary badge-sm cursor-help select-none"
                    >
                        Level {difficulty}
                    </span>
                </div>
            {/if}

            <!-- Retention Aid -->
            {#if retentionAid && isAnswered}
                <div
                    class="tooltip tooltip-top flex items-center justify-center"
                    data-tip="Retention Aid"
                >
                    <div
                        class="badge badge-info badge-sm gap-1 cursor-help select-none overflow-hidden"
                    >
                        <svg
                            class="w-3 h-3 flex-shrink-0"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                            />
                        </svg>
                        <span class="inline-block max-w-32 truncate">
                            <MarkdownContent
                                content={retentionAid}
                                class="text-xs inline"
                            />
                        </span>
                    </div>
                </div>
            {/if}
        </div>
    </div>

    {#if isAnswered}
        <button
            style="anchor-name: --toolbar-anchor-{questionNumber}"
            popovertarget="toolbar-popover-{questionNumber}"
            class="flex items-center gap-1 px-2 py-1 rounded-full bg-base-200/50 hover:bg-base-200 border border-base-300/50 hover:border-base-300 transition-all duration-200 shadow-sm cursor-pointer"
            title="Actions"
        >
            {#if hasExplanation}
                <div
                    class="w-6 h-6 rounded-full bg-info/10 flex items-center justify-center"
                >
                    <svg
                        class="w-3.5 h-3.5 text-info"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                    </svg>
                </div>
            {/if}
            <div
                class="w-6 h-6 rounded-full bg-error/10 flex items-center justify-center"
            >
                <svg
                    class="w-3.5 h-3.5 text-error"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                    />
                </svg>
            </div>
        </button>

        <!-- Context Menu Popover -->
        <div
            popover="auto"
            id="toolbar-popover-{questionNumber}"
            style="position-anchor: --toolbar-anchor-{questionNumber}; position-area: block-end; margin-block-start: 0.5rem;"
            class="bg-base-100 rounded-xl w-48 p-2 shadow-lg border border-base-300 popover-menu"
        >
            {#if hasExplanation}
                <button
                    onclick={toggleExplanation}
                    class="flex items-center gap-2 w-full px-3 py-2 text-sm text-base-content hover:bg-base-200 transition-colors duration-150 rounded-lg"
                >
                    <svg
                        class="w-4 h-4 text-info"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                    </svg>
                    {showExplanation ? "Hide" : "Show"} Explanation
                </button>
            {/if}

            <button
                onclick={clearAnswer}
                class="flex items-center gap-2 w-full px-3 py-2 text-sm text-error hover:bg-error/5 transition-colors duration-150 rounded-lg"
            >
                <svg
                    class="w-4 h-4 text-error"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                    />
                </svg>
                Clear Answer
            </button>
        </div>
    {/if}
</div>

<!-- Explanation Display -->
{#if showExplanation && hasExplanation}
    {#if children}
        {@render children()}
    {/if}
{/if}

<style>
    /* Fallback for browsers without anchor positioning support */
    .popover-menu {
        /* For browsers that don't support anchor positioning, center the popover */
        margin: auto;
        inset: unset;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
    }

    /* Use anchor positioning when supported */
    @supports (position-anchor: --toolbar-anchor) {
        .popover-menu {
            margin: unset;
            inset: unset;
            top: unset;
            left: unset;
            transform: unset;
        }
    }

    /* Smooth popover animations */
    .popover-menu {
        transition:
            opacity 0.2s ease,
            transform 0.2s ease;
    }

    .popover-menu:popover-open {
        opacity: 1;
    }

    .popover-menu:not(:popover-open) {
        opacity: 0;
    }
</style>
