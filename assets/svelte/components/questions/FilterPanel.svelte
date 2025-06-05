<script>
    let {
        difficultyRange = $bindable([1, 5]),
        answerStatus = $bindable("all"),
    } = $props();

    // Handle range input changes
    function handleMinChange(event) {
        const value = parseInt(event.target.value);
        if (value <= difficultyRange[1]) {
            difficultyRange[0] = value;
        }
    }

    function handleMaxChange(event) {
        const value = parseInt(event.target.value);
        if (value >= difficultyRange[0]) {
            difficultyRange[1] = value;
        }
    }

    // Reset filters
    function resetFilters() {
        difficultyRange = [1, 5];
        answerStatus = "all";
    }
</script>

<div class="bg-base-200/50 rounded-lg p-4 space-y-6">
    <div class="flex items-center justify-between">
        <h3 class="text-lg font-semibold text-base-content">Filters</h3>
        <button
            class="btn btn-ghost btn-sm text-base-content/70 hover:text-base-content"
            onclick={resetFilters}
        >
            Reset All
        </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Difficulty Range -->
        <div class="space-y-3">
            <label
                for="difficulty-range"
                class="text-sm font-medium text-base-content"
                >Difficulty Level</label
            >
            <div class="space-y-3">
                <!-- Range Display -->
                <div
                    class="flex items-center justify-between text-sm text-base-content/70"
                >
                    <span>Level {difficultyRange[0]}</span>
                    <span>to</span>
                    <span>Level {difficultyRange[1]}</span>
                </div>

                <!-- Min Range -->
                <div class="space-y-1">
                    <label for="min-range" class="text-xs text-base-content/60"
                        >Minimum</label
                    >
                    <input
                        type="range"
                        min="1"
                        max="5"
                        value={difficultyRange[0]}
                        oninput={handleMinChange}
                        class="range range-primary range-sm"
                    />
                    <div
                        class="w-full flex justify-between text-xs px-2 text-base-content/40"
                    >
                        <span>1</span>
                        <span>2</span>
                        <span>3</span>
                        <span>4</span>
                        <span>5</span>
                    </div>
                </div>

                <!-- Max Range -->
                <div class="space-y-1">
                    <label for="max-range" class="text-xs text-base-content/60"
                        >Maximum</label
                    >
                    <input
                        type="range"
                        min="1"
                        max="5"
                        value={difficultyRange[1]}
                        oninput={handleMaxChange}
                        class="range range-primary range-sm"
                    />
                    <div
                        class="w-full flex justify-between text-xs px-2 text-base-content/40"
                    >
                        <span>1</span>
                        <span>2</span>
                        <span>3</span>
                        <span>4</span>
                        <span>5</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Answer Status -->
        <div class="space-y-3">
            <label
                for="answer-status"
                class="text-sm font-medium text-base-content"
                >Answer Status</label
            >
            <div class="space-y-2">
                <label class="flex items-center gap-2 cursor-pointer">
                    <input
                        type="radio"
                        bind:group={answerStatus}
                        value="all"
                        class="radio radio-primary radio-sm"
                    />
                    <span class="text-sm text-base-content">All Questions</span>
                </label>

                <label class="flex items-center gap-2 cursor-pointer">
                    <input
                        type="radio"
                        bind:group={answerStatus}
                        value="answered"
                        class="radio radio-primary radio-sm"
                    />
                    <span class="text-sm text-base-content">Answered</span>
                </label>

                <label class="flex items-center gap-2 cursor-pointer">
                    <input
                        type="radio"
                        bind:group={answerStatus}
                        value="unanswered"
                        class="radio radio-primary radio-sm"
                    />
                    <span class="text-sm text-base-content">Unanswered</span>
                </label>
            </div>
        </div>
    </div>

    <!-- Active Filters Summary -->
    <div class="flex flex-wrap gap-2 pt-2 border-t border-base-300">
        {#if difficultyRange[0] !== 1 || difficultyRange[1] !== 5}
            <div class="badge badge-primary gap-1">
                <span
                    >Difficulty: {difficultyRange[0]}-{difficultyRange[1]}</span
                >
            </div>
        {/if}

        {#if answerStatus !== "all"}
            <div class="badge badge-secondary gap-1">
                <span
                    >{answerStatus === "answered"
                        ? "Answered Only"
                        : "Unanswered Only"}</span
                >
            </div>
        {/if}

        {#if difficultyRange[0] === 1 && difficultyRange[1] === 5 && answerStatus === "all"}
            <span class="text-xs text-base-content/50">No active filters</span>
        {/if}
    </div>
</div>
