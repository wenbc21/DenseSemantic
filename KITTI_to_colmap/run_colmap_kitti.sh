# Please specify SEQUENCE, PROJECT_ROOT and ROOT_DIR
# SEQUENCE: pre-processed sequence id
# PROJECT_ROOT: root directory of the colmap project to save the results
# ROOT_DIR: root directory of the dataset (pre-processed)
SEQUENCE='2013_05_28_drive_0009_sync'
SEQUENCE_CLIP='seq_001'
PROJECT_ROOT='/mnt/slurm_home/bcwen/DenseSemantic/KITTI_to_colmap/colmap_res'
ROOT_DIR='/mnt/slurm_home/bcwen/DenseSemantic/KITTI_to_colmap/KITTI-colmap'
PROJECT_PATH=${PROJECT_ROOT}/${SEQUENCE}/${SEQUENCE_CLIP}

# drive_0000: seq_001 - seq_022 # done
# drive_0002: seq_009 - seq_038
# drive_0003: seq_001 - seq_003 # done
# drive_0004: seq_001 - seq_023 # done
# drive_0005: seq_001 - seq_013 # done
# drive_0006: seq_001 - seq_019 # done
# drive_0007: seq_001 - seq_010 # done
# drive_0009: seq_001 - seq_028
# drive_0010: seq_001 - seq_006 # done

WORK_SPACE="$PWD"

if [ ! -d ${PROJECT_PATH} ]; then
    mkdir -p ${PROJECT_PATH}
fi
cd ${PROJECT_PATH}

/mnt/slurm_home/bcwen/colmap/bin/colmap feature_extractor \
--ImageReader.camera_model SIMPLE_PINHOLE  \
--ImageReader.single_camera 1 \
--ImageReader.camera_params 552.554261,682.049453,238.769549 \
--database_path database.db \
--image_path ${ROOT_DIR}/${SEQUENCE}/${SEQUENCE_CLIP}

python3 ${WORK_SPACE}/KITTI_to_colmap/colmap_kitti.py \
--project_path ${PROJECT_PATH} \
--data_path ${ROOT_DIR} \
--sequence ${SEQUENCE}

TRIANGULATED_DIR=${PROJECT_PATH}/triangulated/sparse/model
if [ ! -d ${TRIANGULATED_DIR} ]; then
    mkdir -p ${TRIANGULATED_DIR}
fi

/mnt/slurm_home/bcwen/colmap/bin/colmap exhaustive_matcher \
--database_path database.db 
/mnt/slurm_home/bcwen/colmap/bin/colmap point_triangulator \
--database_path database.db \
--image_path ${ROOT_DIR}/${SEQUENCE}/${SEQUENCE_CLIP} \
--input_path created/sparse/model --output_path triangulated/sparse/model

/mnt/slurm_home/bcwen/colmap/bin/colmap image_undistorter \
    --image_path ${ROOT_DIR}/${SEQUENCE}/${SEQUENCE_CLIP} \
    --input_path triangulated/sparse/model \
    --output_path dense
/mnt/slurm_home/bcwen/colmap/bin/colmap patch_match_stereo \
    --workspace_path dense
/mnt/slurm_home/bcwen/colmap/bin/colmap stereo_fusion \
    --workspace_path dense \
    --output_path dense/fused.ply

# colmap delaunay_mesher \
#     --input_path dense \
#     --output_path dense/meshed-delaunay.ply