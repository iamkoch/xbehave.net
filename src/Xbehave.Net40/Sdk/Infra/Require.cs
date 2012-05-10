﻿// <copyright file="Require.cs" company="Adam Ralph">
//  Copyright (c) Adam Ralph. All rights reserved.
// </copyright>

namespace Xbehave.Sdk.Infra
{
    using System;

    internal static class Require
    {
        public static void NotNull<T>([ValidatedNotNull]T arg, string parameterName) where T : class
        {
            if (arg == null)
            {
                throw new ArgumentNullException(parameterName);
            }
        }

        private sealed class ValidatedNotNullAttribute : Attribute
        {
        }
    }
}