## Manual Video Mapping

Use this guide once a school has uploaded their “camera 2” clips and you want to piggy‑back them on the same TrackMan `PlayID` order that the dashboard already uses for the Edger camera.

1. **Record the session in the dashboard** – go to the **Video Upload** tab, pick the TrackMan session that matches the incoming clips, add any context, and save so `data/video_upload_sessions.csv` stores the right `session_id`.
2. **Build a manifest** – create a simple CSV (for example, `uploads/manifest.csv`) with these columns:
   * `cloudinary_url` (required) – the Cloudinary delivery URL you got after the school uploaded the clip for camera 2 (they should upload clips sequentially).
   * `cloudinary_public_id` (optional) – if you already know the public ID, include it so the field in `data/video_map.csv` matches what the cloud UI expects.
3. **Run the mapping script**:
   ```sh
   Rscript map_manual_video_uploads.R \
     --session-id <TrackMan session id from the UI> \
     --manifest uploads/manifest.csv \
     --camera-slot VideoClip2 \
     --camera-name ManualCamera \
     --camera-target ManualUpload
   ```
   The script walks the TrackMan CSVs under `data/practice` and `data/v3`, picks the `PlayID`s for the selected session, and writes sequential `VideoClip2` rows into `data/video_map.csv`.
4. **Refresh the dashboard** – once `data/video_map.csv` contains the new rows, the dashboard will show “camera 2” clips alongside the Edger footage for each pitch.

### Automated upload + mapping

If you want the process to be fully automatic:

1. **Store the clips** in a local folder named however the school prefers (e.g. `uploads/session-123`). Make sure the clip filenames preserve the pitch order (lexicographic order or numeric prefix).
2. **Run the bundled script** to upload and assign them in one go:
   ```sh
   export CLOUDINARY_CLOUD_NAME=pitchingcoachu
   export CLOUDINARY_UPLOAD_PRESET=pcu_notes_unsigned
   Rscript upload_camera2_clips.R \
     --session-id 20251018-BrazellField-Private-1 \
     --clips-dir uploads/session-123 \
     --camera-slot VideoClip2 \
     --manifest-out uploads/session-123-manifest.csv
   ```
   The script uploads every matching clip (mp4/mov/avi) to Cloudinary, writes an optional manifest, then uses `session_id` to look up the TrackMan CSV and map the Cloudinary URLs into `data/video_map.csv`.
3. **Skip the manual manifest** – because the script writes its own manifest and immediately calls the mapping helper, you only need to worry about recording the session in the dashboard beforehand.

You can wrap this command in a small watcher (e.g. `fswatch`/`entr`) or trigger it whenever a school drops new files so the whole flow stays hands-off after the initial upload.

### Direct dashboard uploads

The Video Upload tab now includes an upload control, so schools can select the clips straight from their machine once they pick the matching TrackMan session:

1. Select the session (same as before) and leave the form saved.
2. Use the “Choose clips” button to add the ordered video files (mp4/mov/avi). Browser uploads preserve order if you name them appropriately (e.g. `001.mp4`, `002.mp4`).
3. Click **Upload to Cloudinary + Map** – the dashboard will stream each clip to Cloudinary, build the manifest, and map every URL into `data/video_map.csv` automatically.
4. The success banner below the uploader confirms the mapping and you can refresh the dashboard to see camera 2 available for each pitch.

Repeat for each new session; the script overwrites any prior assignments for the same `session_id` + `camera_slot` combination so you can re-run if a batch needs to be remapped.
