# -*- coding: utf-8 -*-
# -*- python -*-

import numpy as np
import scipy.ndimage as nd
import matplotlib.pyplot as plt

#from openalea.image.serial.all import imread
#from timagetk.components import imread
import openalea.tissue_nukem_3d.microscopy_images.read_microscopy_image
reload(openalea.tissue_nukem_3d.microscopy_images.read_microscopy_image)
from openalea.tissue_nukem_3d.microscopy_images.read_microscopy_image import read_tiff_image

from timagetk.components import SpatialImage
from openalea.cellcomplex.property_topomesh.utils.array_tools import array_unique

def spherical_structuring_element(radius=1.0, voxelsize=(1.,1.,1.)):
    neighborhood = np.array(np.ceil(radius/np.array(voxelsize)),int)
    structuring_element = np.zeros(tuple(2*neighborhood+1),np.uint8)

    neighborhood_coords = np.mgrid[-neighborhood[0]:neighborhood[0]+1,-neighborhood[1]:neighborhood[1]+1,-neighborhood[2]:neighborhood[2]+1]
    neighborhood_coords = np.concatenate(np.concatenate(np.transpose(neighborhood_coords,(1,2,3,0)))) + neighborhood
    neighborhood_coords = array_unique(neighborhood_coords)
        
    neighborhood_distance = np.linalg.norm(neighborhood_coords*voxelsize - neighborhood*voxelsize,axis=1)
    neighborhood_coords = neighborhood_coords[neighborhood_distance<=radius]
    neighborhood_coords = tuple(np.transpose(neighborhood_coords))
    structuring_element[neighborhood_coords] = 1

    return structuring_element
    

filename = '/home/verger/Research/Image_analysis/PCscreen/C1-20180104_PI-Col0_2.tif'

# parameters
sigma = 3
threshold = 5000.
erosion_radius_1 = 8
erosion_radius_2 = 10

# Read and display stack
#img = imread(filename)
img = read_tiff_image(filename,channel_names=['PI',None,None],pattern='ZXYC')
voxelsize = [1,1,1]
img = SpatialImage(img,voxelsize=tuple(list(voxelsize)))
voxelsize = np.array(img.voxelsize)
world.add(img,"image",colormap='invert_grey')

# Gaussian filter
filtered_img = nd.gaussian_filter(img,sigma/voxelsize)
filtered_img = SpatialImage(filtered_img,voxelsize=img.voxelsize)
world.add(filtered_img,'gaussian_image',colormap='invert_grey')

# Binary image
binary_img = SpatialImage((filtered_img>threshold).astype(np.uint16),voxelsize=img.voxelsize)
for z in xrange(img.shape[2]):
    binary_img[:,:,z][np.sum(binary_img[:,:,:z],axis=2)>0] = 1
world.add(binary_img,'binary_image',colormap='jet',bg_id=0,intensity_range=(0,2))
    
# Erosions of binary image
structuring_element_1 = spherical_structuring_element(erosion_radius_1,voxelsize)
eroded_binary_image_1 = nd.binary_erosion(binary_img,structuring_element_1).astype(np.uint16)
eroded_binary_image_1 = SpatialImage(eroded_binary_image_1,voxelsize=img.voxelsize)
for z in xrange(img.shape[2]):
    eroded_binary_image_1[:,:,z][np.sum(eroded_binary_image_1[:,:,:z],axis=2)>0] = 1

structuring_element_2 = spherical_structuring_element(erosion_radius_2-erosion_radius_1,voxelsize)
eroded_binary_image_2 = nd.binary_erosion(eroded_binary_image_1,structuring_element_2).astype(np.uint16)
eroded_binary_image_2 = SpatialImage(eroded_binary_image_2,voxelsize=img.voxelsize)
for z in xrange(img.shape[2]):
    eroded_binary_image_2[:,:,z][np.sum(eroded_binary_image_2[:,:,:z],axis=2)>0] = 1
        
mask_img = eroded_binary_image_1-eroded_binary_image_2
world.add(mask_img,'mask_image',colormap='jet',bg_id=0,intensity_range=(0.5,2.5))

# Stack clipping
L1_slice = (img*mask_img).max(axis=2)

# Output
figure = plt.figure(0)
figure.clf()

figure.add_subplot(1,2,1)
figure.gca().imshow(L1_slice,cmap="Greys",vmin=0,vmax=60000)

figure.add_subplot(1,2,2)
figure.gca().imshow(img.max(axis=2),cmap="Greys",vmin=0,vmax=60000)

figure.set_size_inches(20,10)
figure.savefig(filename[:-7]+"_projections.png")

