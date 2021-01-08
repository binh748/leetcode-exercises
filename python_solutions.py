"""Contains my solutions to various Python problems on LeetCode that I find
particularly instructive. For some problems, I've writen multiple answers where one is usually the
most optimal version."""

# 283. Move Zeroes

class Solution:
    def moveZeroes(self, nums: List[int]) -> None:
        """
        Do not return anything, modify nums in-place instead.
        """
        # The key here is to work the list backwards instead of forwards
        # so that way I don't move zeroes backwards, which is 1) inefficient as
        # will take more steps to move the zeroes to the back of the list
        # and 2) will cause some zeroes to be stuck (e.g. input: [0, 0, 1])

        # When working with lists going backwards, be very careful with my
        # range values and how I offset my i's and j's
        for i in range(len(nums)-1, -1, -1):
            if nums[i] == 0:
                for j in range(i, len(nums)-1):
                    temp = nums[j]
                    nums[j] = nums[j+1]
                    nums[j+1] = temp


n = 1000
for a in range(1, n+1):
    for b in range(1, n+1):
        for c in range(1, n+1):
            for d in range(1, n+1):
                if a^3 + b^3 == c^3 + d^3:
                    print(a, b, c, d)
