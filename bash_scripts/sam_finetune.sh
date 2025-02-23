python part_segmentation/finetune_sam.py --blender --run_name rebuttal_full \
 --wandb --use_dp -dp 3 --batch_size 24 --data_dir /home/dingyi/real2code/real2code_dataset_v0 -sl

python part_segmentation/finetune_sam.py --blender --run_name scissors_eyeglasses_only \
 --wandb --use_dp -dp 3 --batch_size 24 --data_dir /home/dingyi/real2code/real2code_dataset_v0 -sl  --rebuttal_objects