#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput

#ifdef MESHLET_VISIBILITY_BUFFER_RASTER_PASS_OUTPUT
@group(0) @binding(0) var meshlet_visibility_buffer: texture_storage_2d<r64uint, read>; // Per pixel
#else
@group(0) @binding(0) var meshlet_visibility_buffer: texture_storage_2d<r32uint, read>; // Per pixel
#endif
@group(0) @binding(1) var<storage, read> meshlet_cluster_instance_ids: array<u32>;  // Per cluster
@group(0) @binding(2) var<storage, read> meshlet_instance_material_ids: array<u32>; // Per entity instance
var<push_constant> view_width: u32;

/// This pass writes out the depth texture.
@fragment
fn resolve_depth(in: FullscreenVertexOutput) -> @builtin(frag_depth) f32 {
    let visibility = textureLoad(meshlet_visibility_buffer, vec2<u32>(in.position.xy)).x;
#ifdef MESHLET_VISIBILITY_BUFFER_RASTER_PASS_OUTPUT
    return bitcast<f32>(u32(visibility >> 32u));
#else
    return bitcast<f32>(visibility);
#endif
}

/// This pass writes out the material depth texture.
#ifdef MESHLET_VISIBILITY_BUFFER_RASTER_PASS_OUTPUT
@fragment
fn resolve_material_depth(in: FullscreenVertexOutput) -> @builtin(frag_depth) f32 {
    let visibility = textureLoad(meshlet_visibility_buffer, vec2<u32>(in.position.xy)).x;

    let depth = visibility >> 32u;
    if depth == 0lu { return 0.0; }

    let cluster_id = u32(visibility) >> 7u;
    let instance_id = meshlet_cluster_instance_ids[cluster_id];
    let material_id = meshlet_instance_material_ids[instance_id];
    return f32(material_id) / 65535.0;
}
#endif
