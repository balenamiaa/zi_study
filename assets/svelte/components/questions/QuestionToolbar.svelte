<script>
    import { FolderPlusIcon } from "lucide-svelte";
    import MarkdownContent from "../MarkdownContent.svelte";
    import AddToSetsModal from "./AddToSetsModal.svelte";

    let {
        questionNumber,
        difficulty,
        retentionAid,
        hasExplanation = false,
        isAnswered = false,
        showExplanation = $bindable(false),
        onClearAnswer,
        questionId,
        userQuestionSets,
        live,
        class: userClass = "",
        children,
    } = $props();

    let showAddToSetsModal = $state(false);

    function toggleExplanation() {
        showExplanation = !showExplanation;
    }

    function clearAnswer() {
        if (onClearAnswer) {
            onClearAnswer();
        }
    }

    function openAddToSetsModal() {
        showAddToSetsModal = true;
    }

    function closeAddToSetsModal() {
        showAddToSetsModal = false;
    }
</script>

<AddToSetsModal
    isOpen={showAddToSetsModal}
    onClose={closeAddToSetsModal}
    {questionId}
    {userQuestionSets}
    {live}
/>

<div class="mb-4 {userClass}">
    <!-- Responsive layout with flex-wrap -->
    <div class="flex items-center flex-wrap gap-3 w-full">
        <!-- Question Number -->
        <div
            class="w-8 h-8 bg-primary text-primary-content rounded-full flex items-center justify-center text-sm font-bold shrink-0"
        >
            {questionNumber}
        </div>

        <div
            class="flex flex-1 min-w-0 items-center justify-start gap-1 md:gap-2"
        >
            <!-- Difficulty Badge -->
            {#if difficulty}
                <div
                    class="tooltip tooltip-top flex items-center justify-center shrink-0"
                    data-tip="Difficulty"
                >
                    <span
                        class="badge badge-secondary badge-sm cursor-help select-none text-xs md:text-sm"
                    >
                        Level {difficulty}
                    </span>
                </div>
            {/if}

            <!-- Retention Aid -->
            {#if retentionAid && isAnswered}
                <div
                    class="flex flex-1 min-w-0 items-center justify-start mx-2"
                >
                    <div class="relative group w-full">
                        <div
                            class="badge badge-info gap-1 cursor-help select-none py-2 min-h-[2rem] h-[3rem] w-full overflow-hidden flex items-center"
                            tabindex="0"
                            role="button"
                            aria-label="Retention aid - hover or focus for full content"
                            aria-describedby="retention-tooltip-{questionNumber}"
                            onkeydown={(e) =>
                                e.key === "Enter" || e.key === " "
                                    ? e.currentTarget.focus()
                                    : null}
                        >
                            <svg
                                class="w-3 h-3 shrink-0"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                aria-hidden="true"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                                />
                            </svg>
                            <div
                                class="flex-1 h-full overflow-y-auto retention-aid-scroll pr-1"
                            >
                                <MarkdownContent
                                    content={retentionAid}
                                    class="text-xs leading-tight"
                                />
                            </div>
                        </div>

                        <!-- Custom Tooltip -->
                        <div
                            id="retention-tooltip-{questionNumber}"
                            class="absolute {questionNumber === 1
                                ? 'top-full mt-2'
                                : 'bottom-full mb-2'} left-1/2 z-[9999]
                                   opacity-0 scale-95 group-hover:opacity-100 group-hover:scale-100 group-focus-within:opacity-100 group-focus-within:scale-100
                                   transition-all duration-200 ease-out pointer-events-none
                                   bg-base-100 border border-base-300 rounded-lg shadow-xl p-4 max-w-sm w-max min-w-[16rem]
                                   -translate-x-1/2 transform-gpu will-change-transform"
                            role="tooltip"
                        >
                            <MarkdownContent
                                content={retentionAid}
                                class="text-sm leading-relaxed max-h-64 overflow-y-auto"
                            />
                            <!-- Tooltip Arrow -->
                            <div
                                class="absolute {questionNumber === 1
                                    ? 'bottom-full'
                                    : 'top-full'} left-1/2 transform -translate-x-1/2
                                        border-4 border-transparent {questionNumber ===
                                1
                                    ? 'border-b-base-100'
                                    : 'border-t-base-100'}"
                            ></div>
                        </div>
                    </div>
                </div>
            {/if}
        </div>

        <!-- Action Bar -->
        <div class="flex justify-center w-full sm:w-auto sm:justify-end">
            <div
                class="inline-flex items-center gap-1 px-2 py-0.5 bg-gradient-to-r from-base-100 to-base-200/50 border border-base-300/60 rounded-full shadow-md backdrop-blur-sm hover:shadow-lg transition-all duration-300"
            >
                <!-- Add to Sets Button (always visible) -->
                <div class="tooltip tooltip-top" data-tip="Add to Sets">
                    <button
                        onclick={openAddToSetsModal}
                        aria-label="Add to Question Sets"
                        class="btn btn-circle btn-xs bg-primary/15 hover:bg-primary/25 border-primary/30 hover:border-primary/40 text-primary hover:text-primary-content transition-all duration-200 hover:scale-105 active:scale-95"
                    >
                        <FolderPlusIcon class="w-3.5 h-3.5" />
                    </button>
                </div>

                {#if isAnswered}
                    <div class="w-px h-4 bg-base-300/50"></div>

                    {#if hasExplanation}
                        <div
                            class="tooltip tooltip-top"
                            data-tip="{showExplanation
                                ? 'Hide'
                                : 'Show'} Explanation"
                        >
                            <button
                                onclick={toggleExplanation}
                                aria-label="Toggle Explanation"
                                class="btn btn-circle btn-xs bg-info/15 hover:bg-info/25 border-info/30 hover:border-info/40 text-info hover:text-info-content transition-all duration-200 hover:scale-105 active:scale-95"
                            >
                                <svg
                                    class="w-3.5 h-3.5"
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
                            </button>
                        </div>
                    {/if}

                    {#if hasExplanation}
                        <div class="w-px h-4 bg-base-300/50"></div>
                    {/if}

                    <div class="tooltip tooltip-top" data-tip="Clear Answer">
                        <button
                            onclick={clearAnswer}
                            aria-label="Clear Answer"
                            class="btn btn-circle btn-xs bg-error/15 hover:bg-error/25 border-error/30 hover:border-error/40 text-error hover:text-error-content transition-all duration-200 hover:scale-105 active:scale-95"
                        >
                            <svg
                                class="w-3.5 h-3.5"
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
                        </button>
                    </div>
                {/if}
            </div>
        </div>
    </div>
</div>

{#if showExplanation && hasExplanation}
    {#if children}
        {@render children()}
    {/if}
{/if}

<style>
    .btn {
        transition:
            background-color 0.2s ease,
            border-color 0.2s ease,
            transform 0.15s ease,
            box-shadow 0.2s ease;
    }

    .btn:hover {
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }

    .btn:active {
        transform: scale(0.95);
    }

    /* Action bar hover effect */
    .inline-flex:hover {
        transform: translateY(-1px);
    }

    /* Retention aid scrollbar */
    .retention-aid-scroll {
        scrollbar-width: thin;
        scrollbar-color: rgba(255, 255, 255, 0.8) rgba(255, 255, 255, 0.2);
    }

    .retention-aid-scroll::-webkit-scrollbar {
        width: 4px;
    }

    .retention-aid-scroll::-webkit-scrollbar-track {
        background: rgba(255, 255, 255, 0.2);
        border-radius: 2px;
    }

    .retention-aid-scroll::-webkit-scrollbar-thumb {
        background-color: rgba(255, 255, 255, 0.8);
        border-radius: 2px;
    }

    .retention-aid-scroll::-webkit-scrollbar-thumb:hover {
        background-color: rgba(255, 255, 255, 1);
    }

    /* Prevent tooltip flicker by ensuring stable positioning */
    [role="tooltip"] {
        transform-origin: center top;
    }

    [role="tooltip"].top-full {
        transform-origin: center bottom;
    }

    /* Ensure retention aid uses maximum available width */
    .badge {
        min-width: 0;
        flex-shrink: 1;
    }
</style>
