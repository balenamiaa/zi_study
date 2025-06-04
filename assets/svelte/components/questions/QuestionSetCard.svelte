<script>
    let { questionSet } = $props();

    // Calculate completion percentage
    let completionPercentage = $derived.by(() => {
        const total = questionSet.stats.total_answers;
        if (total === 0) return 0;
        return Math.round((total / (questionSet.num_questions || 1)) * 100);
    });

    // Calculate accuracy percentage
    let accuracyPercentage = $derived.by(() => {
        const correct = questionSet.stats.correct_answers;
        const total = questionSet.stats.total_answers;
        if (total === 0) return 0;
        return Math.round((correct / total) * 100);
    });

    // Format date
    function formatDate(dateString) {
        return new Date(dateString).toLocaleDateString("en-US", {
            year: "numeric",
            month: "short",
            day: "numeric",
        });
    }

    function navigateToQuestionSet() {
        // This will be implemented with proper routing later
    }
</script>

<div
    class="card bg-base-200 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer transform hover:-translate-y-1 group"
    onclick={navigateToQuestionSet}
    onkeydown={(e) => {
        if (e.key === "Enter" || e.key === " ") {
            navigateToQuestionSet();
        }
    }}
    aria-label={questionSet.title}
    role="button"
    tabindex="0"
>
    <!-- Card Header -->
    <div class="card-body p-6">
        <div class="flex items-start justify-between mb-4">
            <div class="flex-1">
                <h3
                    class="card-title text-lg font-bold text-base-content group-hover:text-primary transition-colors duration-200"
                >
                    {questionSet.title}
                </h3>
                {#if questionSet.description}
                    <p class="text-base-content/70 text-sm mt-1 line-clamp-2">
                        {questionSet.description}
                    </p>
                {/if}
            </div>

            {#if questionSet.is_private}
                <div class="badge badge-secondary badge-sm">Private</div>
            {:else}
                <div class="badge badge-primary badge-sm">Public</div>
            {/if}
        </div>

        <!-- Stats -->
        <div class="grid grid-cols-2 gap-4 mb-4">
            <div class="bg-base-100 rounded-lg p-3">
                <div
                    class="text-xs text-base-content/60 uppercase tracking-wide"
                >
                    Questions
                </div>
                <div class="text-2xl font-bold text-base-content">
                    {questionSet.num_questions}
                </div>
            </div>
            <div class="bg-base-100 rounded-lg p-3">
                <div
                    class="text-xs text-base-content/60 uppercase tracking-wide"
                >
                    Completed
                </div>
                <div class="text-2xl font-bold text-primary">
                    {completionPercentage}%
                </div>
            </div>
        </div>

        <!-- Progress bars -->
        {#if questionSet.stats.total_answers > 0}
            <div class="space-y-2 mb-4">
                <div class="flex justify-between text-xs text-base-content/70">
                    <span>Accuracy</span>
                    <span>{accuracyPercentage}%</span>
                </div>
                <progress
                    class="progress progress-success w-full"
                    value={accuracyPercentage}
                    max="100"
                ></progress>
            </div>
        {/if}

        <!-- Tags -->
        {#if questionSet.tags && questionSet.tags.length > 0}
            <div class="flex flex-wrap gap-1 mb-4">
                {#each questionSet.tags.slice(0, 3) as tag}
                    <span class="badge badge-outline badge-xs">{tag.name}</span>
                {/each}
                {#if questionSet.tags.length > 3}
                    <span class="badge badge-outline badge-xs"
                        >+{questionSet.tags.length - 3}</span
                    >
                {/if}
            </div>
        {/if}

        <!-- Footer -->
        <div
            class="flex items-center justify-between text-xs text-base-content/60"
        >
            <div class="flex items-center gap-1">
                {#if questionSet.owner}
                    <svg
                        class="w-3 h-3"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                        />
                    </svg>
                    <span>{questionSet.owner.email}</span>
                {/if}
            </div>
            <div>
                {formatDate(questionSet.updated_at)}
            </div>
        </div>
    </div>

    <!-- Hover overlay -->
    <div
        class="absolute inset-0 bg-primary/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-2xl pointer-events-none"
    ></div>
</div>

<style>
    .line-clamp-2 {
        display: -webkit-box;
        -webkit-line-clamp: 2;
        line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }
</style>
