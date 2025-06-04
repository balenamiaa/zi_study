<script>
    import QuestionSetCard from "../components/QuestionSetCard.svelte";
    import { SearchIcon } from "lucide-svelte";

    let { live, questionSets } = $props();

    let searchQuery = $state("");
    let filteredQuestionSets = $derived(
        questionSets?.filter(
            (qs) =>
                qs.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
                qs.description
                    ?.toLowerCase()
                    .includes(searchQuery.toLowerCase()) ||
                qs.tags.some((tag) =>
                    tag.name.toLowerCase().includes(searchQuery.toLowerCase()),
                ),
        ) || [],
    );

    console.log("Question Sets:", questionSets);
</script>

<div class="min-h-screen bg-base-100 p-4 md:p-6 lg:p-8">
    <div class="max-w-7xl mx-auto">
        <!-- Header -->
        <div class="mb-8">
            <h1 class="text-4xl font-bold text-base-content mb-2">
                Question Sets
            </h1>
            <p class="text-base-content/70 text-lg">
                Discover and practice with our collection of question sets
            </p>
        </div>

        <!-- Search and Stats -->
        <div
            class="mb-8 flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between"
        >
            <label for="search" class="input relative flex-1 max-w-md">
                <SearchIcon class="h-5 w-5" />
                <input
                    type="search"
                    bind:value={searchQuery}
                    placeholder="Search question sets..."
                    class="grow"
                />
            </label>

            <div class="flex items-center gap-2 text-base-content/70">
                <span class="text-sm"
                    >{filteredQuestionSets.length} of {questionSets?.length ||
                        0} sets</span
                >
            </div>
        </div>

        <!-- Question Sets Grid -->
        {#if filteredQuestionSets.length === 0}
            <div class="text-center py-16">
                <div
                    class="w-24 h-24 mx-auto mb-4 bg-base-200 rounded-full flex items-center justify-center"
                >
                    <svg
                        class="w-12 h-12 text-base-content/30"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                        />
                    </svg>
                </div>
                <h3 class="text-xl font-semibold text-base-content mb-2">
                    No question sets found
                </h3>
                <p class="text-base-content/60">
                    Try adjusting your search or check back later for new
                    content.
                </p>
            </div>
        {:else}
            <div
                class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
            >
                {#each filteredQuestionSets as questionSet (questionSet.id)}
                    <QuestionSetCard {questionSet} />
                {/each}
            </div>
        {/if}
    </div>
</div>
