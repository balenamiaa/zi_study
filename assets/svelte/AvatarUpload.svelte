<script>
    import { onMount } from "svelte";

    export let live;

    onMount(() => {
        console.log("AvatarUpload mounted");
        console.log(live);
    });
</script>

<div>A Placeholder for Avatar Upload.</div>
