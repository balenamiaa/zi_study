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
        onclearAnswer,
        questionId,
        live,
        userQuestionSets = null,
        class: userClass = "",
        children,
    } = $props();

    let showAddToSetsModal = $state(false);

    function toggleExplanation() {
        showExplanation = !showExplanation;
    }

    function clearAnswer() {
        if (onclearAnswer) {
            onclearAnswer();
        }
    }

    function openAddToSetsModal() {
        showAddToSetsModal = true;
    }

    function closeAddToSetsModal() {
        showAddToSetsModal = false;
    }
</script>

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
                <div class="flex flex-1 min-w-0 items-center justify-start">
                    <div class="tooltip tooltip-top flex items-center min-w-0">
                        <div
                            class="badge badge-info badge-sm gap-1 cursor-help select-none overflow-hidden"
                        >
                            <svg
                                class="w-3 h-3 shrink-0"
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
                            <span
                                class="inline-flex flex-1 min-w-0 whitespace-nowrap overflow-auto"
                            >
                                <MarkdownContent
                                    content={retentionAid}
                                    class="text-xs inline"
                                />
                            </span>
                        </div>

                        <div class="tooltip-content">
                            <MarkdownContent
                                content={retentionAid}
                                class="text-xs inline"
                            />
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

<!-- Explanation Display -->
{#if showExplanation && hasExplanation}
    {#if children}
        {@render children()}
    {/if}
{/if}

<!-- Add to Sets Modal -->
<AddToSetsModal
    isOpen={showAddToSetsModal}
    onClose={closeAddToSetsModal}
    {questionId}
    {live}
    {userQuestionSets}
/>

<style>
    /* Enhanced button animations */
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
</style>
